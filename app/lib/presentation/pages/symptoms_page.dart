import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_chrome.dart';
import '../widgets/dosis_widgets.dart';

/// "Como se sente hoje?" (RF10): grava pelo caso de uso [RegisterSymptoms].
class SymptomsPage extends ConsumerStatefulWidget {
  const SymptomsPage({super.key});

  @override
  ConsumerState<SymptomsPage> createState() => _SymptomsPageState();
}

class _SymptomsPageState extends ConsumerState<SymptomsPage> {
  static const _options = [
    Symptom.pain,
    Symptom.nausea,
    Symptom.dizziness,
    Symptom.fatigue,
    Symptom.palpitation,
    Symptom.other,
  ];

  final _notes = TextEditingController();
  final Set<Symptom> _selected = {};
  bool _normal = false;
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _toggle(Symptom symptom) => setState(() {
        _normal = false;
        if (!_selected.remove(symptom)) _selected.add(symptom);
      });

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(registerSymptomsProvider)(normal: _normal, symptoms: _selected, notes: _notes.text);
    } on ArgumentError catch (error) {
      // Regra de validação (ex.: nada marcado): mostra a mensagem do caso de uso.
      if (mounted) _toast('${error.message}');
      return;
    } catch (error) {
      if (mounted) _toast('Não foi possível salvar: $error');
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;

    // Só confirma depois que o registro foi gravado de verdade.
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.yellow),
                child: const Icon(Icons.check, size: 40, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              const Text('Registro salvo com sucesso', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              const Text('Ele já está no seu histórico', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 20),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fechar')),
            ],
          ),
        ),
      ),
    );
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DosisTopBar(),
      bottomNavigationBar: const DosisBottomNav(popToRoot: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const PageHeader('Como se sente hoje?', backColor: AppColors.yellow),
          const SizedBox(height: 24),
          DosisCard(
            radius: 14,
            onTap: () => setState(() {
              _normal = !_normal;
              if (_normal) _selected.clear();
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
                RadioDot(selected: _normal),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Senti algo diferente', subtitle: 'Você pode marcar mais de um'),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 3.2,
            children: [
              for (final symptom in _options)
                SelectBox(label: symptom.label, selected: _selected.contains(symptom), onTap: () => _toggle(symptom)),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Observação (opcional)', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Como você se sentiu?'),
          ),
          const SizedBox(height: 28),
          FilledButton(onPressed: _saving ? null : _save, child: const Text('Salvar registro')),
        ],
      ),
    );
  }
}