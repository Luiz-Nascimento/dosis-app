import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_widgets.dart';
import 'day_detail_page.dart';
import 'supplement_history_page.dart';

/// "Registros": dias com doses do mês escolhido, mais recentes primeiro, 5 por página.
/// Cada dia mostra também os sintomas registrados nele.
class RecordsPage extends ConsumerStatefulWidget {
  const RecordsPage({super.key});

  @override
  ConsumerState<RecordsPage> createState() => _RecordsPageState();
}

const _months = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

class _RecordsPageState extends ConsumerState<RecordsPage> {
  static const _perPage = 5;
  static const _abbr = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

  int _page = 0;

  /// Mês que está sendo mostrado (só o ano e o mês valem). Começa no mês atual.
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  String _dayLabel(String localDate) {
    final parts = localDate.split('-');
    return '${int.parse(parts[2])} de ${_abbr[int.parse(parts[1]) - 1]}';
  }

  /// "2026-11" para comparar com o início de `localDate` (AAAA-MM-DD).
  String get _monthPrefix => '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

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

  Future<void> _pickMonth(int firstYear) async {
    final now = DateTime.now();
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MonthPicker(initial: _month, firstYear: firstYear, now: now),
    );
    if (picked != null) {
      setState(() {
        _month = picked;
        _page = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doses = ref.watch(doseHistoryProvider).value ?? const <DoseLog>[];
    final symptoms = ref.watch(symptomHistoryProvider).value ?? const <SymptomLog>[];
    final byDay = <String, List<DoseLog>>{};
    for (final dose in doses) {
      byDay.putIfAbsent(dose.localDate, () => []).add(dose);
    }
    final allDays = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final days = allDays.where((d) => d.startsWith(_monthPrefix)).toList();
    final pages = days.isEmpty ? 1 : (days.length / _perPage).ceil();
    final page = _page >= pages ? pages - 1 : _page;
    final visible = days.skip(page * _perPage).take(_perPage).toList();
    // O seletor começa no ano do registro mais antigo (ou no ano atual, se não há nenhum).
    final firstYear = allDays.isEmpty ? DateTime.now().year : int.parse(allDays.last.substring(0, 4));

    return Column(
      children: [
        const SizedBox(height: 8),
        const Text('Registros', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickMonth(firstYear),
          child: Container(
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
                  '${_months[_month.month - 1]} ${_month.year}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down, color: AppColors.yellow),
              ],
            ),
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
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      allDays.isEmpty
                          ? 'Nenhuma dose registrada ainda.'
                          : 'Nenhuma dose registrada em ${_months[_month.month - 1]} de ${_month.year}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                ),
              for (final day in visible) ...[
                DosisCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => DayDetailPage(localDate: day)),
                  ),
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

/// Seletor de mês e ano. Devolve o primeiro dia do mês escolhido.
/// Não deixa escolher meses depois do atual.
class _MonthPicker extends StatefulWidget {
  const _MonthPicker({required this.initial, required this.firstYear, required this.now});

  final DateTime initial;
  final int firstYear;
  final DateTime now;

  @override
  State<_MonthPicker> createState() => _MonthPickerState();
}

class _MonthPickerState extends State<_MonthPicker> {
  late int _year = widget.initial.year;

  @override
  Widget build(BuildContext context) {
    final canGoBack = _year > widget.firstYear;
    final canGoForward = _year < widget.now.year;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: canGoBack ? () => setState(() => _year--) : null,
                  icon: const Icon(Icons.chevron_left),
                  color: AppColors.yellow,
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    '$_year',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: canGoForward ? () => setState(() => _year++) : null,
                  icon: const Icon(Icons.chevron_right),
                  color: AppColors.yellow,
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.3,
              children: [
                for (var month = 1; month <= 12; month++)
                  Opacity(
                    opacity: _year == widget.now.year && month > widget.now.month ? 0.3 : 1,
                    child: SelectBox(
                      label: _months[month - 1].substring(0, 3),
                      height: 44,
                      selected: _year == widget.initial.year && month == widget.initial.month,
                      onTap: () {
                        if (_year == widget.now.year && month > widget.now.month) return;
                        Navigator.of(context).pop(DateTime(_year, month));
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}