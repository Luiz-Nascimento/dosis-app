import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_widgets.dart';
import 'supplement_history_page.dart';

/// "Registros": dias com doses, mais recentes primeiro, 5 por página.
/// Cada dia mostra também os sintomas registrados nele.
class RecordsPage extends ConsumerStatefulWidget {
  const RecordsPage({super.key});

  @override
  ConsumerState<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends ConsumerState<RecordsPage> {
  static const _perPage = 5;
  static const _months = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];
  static const _abbr = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

  int _page = 0;

  String _dayLabel(String localDate) {
    final parts = localDate.split('-');
    return '${int.parse(parts[2])} de ${_abbr[int.parse(parts[1]) - 1]}';
  }

  /// Resumo dos sintomas registrados no dia (`localDate` no formato AAAA-MM-DD).
  String _symptomsOf(String localDate, List<SymptomLog> all) {
    final ofDay = all.where((s) => s.localDate == localDate);
    if (ofDay.isEmpty) return 'Sem registro de sintomas';
    final labels = {
      for (final log in ofDay)
        if (log.status == SymptomStatus.different) ...log.symptoms.map((s) => s.label),
    };
    return labels.isEmpty ? 'Nenhum sintoma' : labels.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final doses = ref.watch(doseHistoryProvider).value ?? const <DoseLog>[];
    final symptoms = ref.watch(symptomHistoryProvider).value ?? const <SymptomLog>[];
    final byDay = <String, List<DoseLog>>{};
    for (final dose in doses) {
      byDay.putIfAbsent(dose.localDate, () => []).add(dose);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final pages = days.isEmpty ? 1 : (days.length / _perPage).ceil();
    final page = _page >= pages ? pages - 1 : _page;
    final visible = days.skip(page * _perPage).take(_perPage).toList();
    final now = DateTime.now();

    return Column(
      children: [
        const SizedBox(height: 8),
        const Text('Registros', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_months[now.month - 1]} ${now.year}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down, color: AppColors.yellow),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              NavCard(
                icon: Icons.bar_chart_rounded,
                title: 'Histórico por suplemento',
                subtitle: 'Consumo e evolução das doses',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SupplementHistoryPage()),
                ),
              ),
              const SizedBox(height: 16),
              if (days.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('Nenhuma dose registrada ainda.', style: TextStyle(color: AppColors.muted))),
                ),
              for (final day in visible) ...[
                DosisCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _dayLabel(day),
                              style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (byDay[day]!.toList()..sort((a, b) => a.takenAt.compareTo(b.takenAt)))
                                  .map((d) => d.name)
                                  .toSet()
                                  .join(' + '),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _symptomsOf(day, symptoms),
                              style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.yellow, size: 28),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
        Pager(page: page, pages: pages, onChanged: (p) => setState(() => _page = p)),
        const SizedBox(height: 8),
      ],
    );
  }
}