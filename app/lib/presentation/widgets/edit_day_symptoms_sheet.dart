import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'auth_widgets.dart';
import 'dosis_widgets.dart';

/// Abre "Editar sintomas" do dia. Devolve `true` se salvou.
Future<bool?> showEditDaySymptomsSheet(
  BuildContext context, {
  required String localDate,
  required List<SymptomLog> logs,
}) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => EditDaySymptomsSheet(localDate: localDate, logs: logs),
    );

class EditDaySymptomsSheet extends ConsumerStatefulWidget {
  const EditDaySymptomsSheet({super.key, required this.localDate, required this.logs});

  final String localDate;
  final List<SymptomLog> logs;

  @override
  ConsumerState<EditDaySymptomsSheet> createState() => _EditDaySymptomsSheetState();
}

class _EditDaySymptomsSheetState extends ConsumerState<EditDaySymptomsSheet> {
  static const _base = [
    Symptom.pain,
    Symptom.nausea,
    Symptom.dizziness,
    Symptom.fatigue,
    Symptom.palpitation,
    Symptom.other,
  ];

  SymptomStatus? _status;
  late final Set<Symptom> _selected;
  late final List<Symptom> _options;
  late final TextEditingController _other;
  late final TextEditingController _notes;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final logs = widget.logs;
    final different = logs.where((l) => l.status == SymptomStatus.different).toList();
    _status = logs.isEmpty ? null : (different.isEmpty ? SymptomStatus.normal : SymptomStatus.different);
    _selected = {for (final log in different) ...log.symptoms};
    // Sintomas que não estão na lista padrão, mas já foram registrados, continuam aparecendo.
    _options = [..._base, ..._selected.where((s) => !_base.contains(s))];
    final otherText = different
        .map((l) => l.otherDescription?.trim() ?? '')
        .firstWhere((t) => t.isNotEmpty, orElse: () => '');
    _other = TextEditingController(text: otherText);
    _notes = TextEditingController(
      text: [
        for (final log in logs)
          if ((log.notes ?? '').trim().isNotEmpty) log.notes!.trim(),
      ].join('\n'),
    );
  }

  @override
  void dispose() {
    _other.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _toggle(Symptom symptom) {
    setState(() {
      if (!_selected.remove(symptom)) _selected.add(symptom);
      _status = _selected.isEmpty ? null : SymptomStatus.different;
    });
  }

  Future<void> _save() async {
    final status = _status;
    if (status == null) {
      setState(() => _error = 'Escolha "Normal" ou marque os sintomas.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(saveDaySymptomsProvider)(
        localDate: widget.localDate,
        existing: widget.logs,
        status: status,
        symptoms: _selected.toList(),
        otherDescription: _other.text,
        notes: _notes.text,
      );
      ref.invalidate(symptomHistoryProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ArgumentError catch (error) {
      if (mounted) setState(() => _error = '${error.message}');
    } on ApiException catch (error) {
      ref.invalidate(symptomHistoryProvider);
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      ref.invalidate(symptomHistoryProvider);
      if (mounted) setState(() => _error = 'Não foi possível salvar. Tente de novo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final normal = _status == SymptomStatus.normal;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text('Editar sintomas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 18),
              DosisCard(
                radius: 14,
                onTap: () => setState(() {
                  _status = SymptomStatus.normal;
                  _selected.clear();
                }),
                child: Row(
                  children: [
                    const Icon(Icons.sentiment_satisfied_alt_outlined, color: AppColors.yellow),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Normal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text('Não senti nada de diferente', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    RadioDot(selected: normal),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Center(child: Text('ou', style: TextStyle(fontSize: 12, color: AppColors.muted))),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 3.2,
                children: [
                  for (final symptom in _options)
                    SelectBox(label: symptom.label, selected: _selected.contains(symptom), onTap: () => _toggle(symptom)),
                ],
              ),
              if (_selected.contains(Symptom.other)) ...[
                const SizedBox(height: 14),
                AuthField(label: 'O que você sentiu?', controller: _other),
              ],
              const SizedBox(height: 16),
              const Text('Observação (opcional)', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(controller: _notes, maxLines: 3, maxLength: 500),
              AuthError(_error),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AuthButton(label: 'Salvar alterações', busy: _saving, onPressed: _save),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}