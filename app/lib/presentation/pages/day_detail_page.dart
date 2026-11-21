import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';
import '../format.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_chrome.dart';
import '../widgets/dosis_widgets.dart';
import '../widgets/edit_day_stack_sheet.dart';
import '../widgets/edit_day_symptoms_sheet.dart';

/// Detalhe de um dia da aba Registros: doses, sintomas e observação.
/// Tocar no stack ou nos sintomas abre a edição. [localDate] vem no formato AAAA-MM-DD.
class DayDetailPage extends ConsumerWidget {
  const DayDetailPage({super.key, required this.localDate});

  final String localDate;

  static const _months = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];

  /// "2026-09-20" vira "20 de setembro de 2026".
  String get _title {
    final parts = localDate.split('-');
    if (parts.length != 3) return localDate;
    return '${int.parse(parts[2])} de ${_months[int.parse(parts[1]) - 1]} de ${parts[0]}';
  }

  /// Sintomas sentidos no dia, sem repetir.
  List<String> _symptomLabels(List<SymptomLog> logs) {
    final labels = <String>{};
    for (final log in logs) {
      if (log.status != SymptomStatus.different) continue;
      for (final symptom in log.symptoms) {
        final other = log.otherDescription?.trim() ?? '';
        labels.add(symptom == Symptom.other && other.isNotEmpty ? 'Outro: $other' : symptom.label);
      }
    }
    return labels.toList();
  }

  void _saved(BuildContext context, bool? ok) {
    if (ok != true || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Alterações salvas.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doses = (ref.watch(doseHistoryProvider).value ?? const <DoseLog>[])
        .where((d) => d.localDate == localDate)
        .toList()
      ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
    final symptomLogs = (ref.watch(symptomHistoryProvider).value ?? const <SymptomLog>[])
        .where((s) => s.localDate == localDate)
        .toList();
    final labels = _symptomLabels(symptomLogs);
    final notes = [
      for (final log in symptomLogs)
        if ((log.notes ?? '').trim().isNotEmpty) log.notes!.trim(),
    ];

    Future<void> editStack() async =>
        _saved(context, await showEditDayStackSheet(context, localDate: localDate, doses: doses));
    Future<void> editSymptoms() async =>
        _saved(context, await showEditDaySymptomsSheet(context, localDate: localDate, logs: symptomLogs));

    return Scaffold(
      appBar: const DosisTopBar(),
      bottomNavigationBar: const DosisBottomNav(popToRoot: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: AppColors.yellow),
              ),
              Expanded(
                child: Text(_title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionTitle('Stack do dia'),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: editStack,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (doses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Nenhuma dose registrada neste dia. Toque para adicionar.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                for (final dose in doses) ...[
                  StackRow(
                    time: formatTime(dose.takenAt),
                    name: dose.name,
                    amount: formatDose(dose.amount, dose.unit),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          const SectionTitle('Como você se sentiu'),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: editSymptoms,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (symptomLogs.isEmpty)
                  const Text(
                    'Sem registro de sintomas neste dia. Toque para adicionar.',
                    style: TextStyle(color: AppColors.muted),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final label in labels.isEmpty ? const ['Nenhum sintoma'] : labels) _Chip(label),
                    ],
                  ),
                const SizedBox(height: 22),
                const SectionTitle('Observação'),
                const SizedBox(height: 12),
                DosisCard(
                  radius: 14,
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      notes.isEmpty ? 'Sem observações.' : notes.join('\n'),
                      style: TextStyle(fontSize: 13, color: notes.isEmpty ? AppColors.muted : null),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.orangeSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800, fontSize: 15)),
    );
  }
}