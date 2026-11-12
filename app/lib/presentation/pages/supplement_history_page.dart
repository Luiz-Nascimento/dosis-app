import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../domain/usecases/get_supplement_history.dart';
import '../format.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_bar_chart.dart';
import '../widgets/dosis_chrome.dart';
import '../widgets/dosis_widgets.dart';

/// "Histórico por suplemento": escolhe o suplemento e o período e vê
/// o gráfico da soma diária, um resumo e todos os registros.
class SupplementHistoryPage extends ConsumerStatefulWidget {
  const SupplementHistoryPage({super.key});

  @override
  ConsumerState<SupplementHistoryPage> createState() => _SupplementHistoryPageState();
}

class _SupplementHistoryPageState extends ConsumerState<SupplementHistoryPage> {
  static const _periods = [7, 30, 90];
  static const _perPage = 8;

  int _days = 30;
  String? _selectedKey;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(supplementHistoryProvider(_days));

    return Scaffold(
      appBar: const DosisTopBar(),
      bottomNavigationBar: const DosisBottomNav(popToRoot: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const PageHeader('Histórico'),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final period in _periods) ...[
                Expanded(
                  child: SelectBox(
                    label: '$period dias',
                    selected: _days == period,
                    onTap: () => setState(() {
                      _days = period;
                      _page = 0;
                    }),
                  ),
                ),
                if (period != _periods.last) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 20),
          ...async.when(
            loading: () => const [
              Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator())),
            ],
            error: (error, _) => [_Message('Não foi possível carregar o histórico: $error')],
            data: (histories) {
              if (histories.isEmpty) {
                return [_Message('Nenhuma dose registrada nos últimos $_days dias.')];
              }
              final history = histories.where((h) => h.key == _selectedKey).firstOrNull ?? histories.first;
              return _content(histories, history);
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _content(List<SupplementHistory> histories, SupplementHistory history) {
    final unit = history.unit.label;
    final pages = (history.logs.length / _perPage).ceil();
    final page = _page >= pages ? pages - 1 : _page;
    final visible = history.logs.skip(page * _perPage).take(_perPage);
    final max = history.referenceMax;

    return [
      const SectionTitle('Suplemento'),
      const SizedBox(height: 12),
      SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: histories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final selected = histories[i].key == history.key;
            return ChoiceChip(
              label: Text(histories[i].name),
              selected: selected,
              showCheckmark: false,
              selectedColor: AppColors.yellow,
              backgroundColor: AppColors.card,
              side: const BorderSide(color: AppColors.border),
              labelStyle: TextStyle(fontWeight: FontWeight.w700, color: selected ? Colors.black : Colors.white),
              onSelected: (_) => setState(() {
                _selectedKey = histories[i].key;
                _page = 0;
              }),
            );
          },
        ),
      ),
      const SizedBox(height: 22),
      SectionTitle('Evolução das doses', subtitle: 'Soma por dia, em $unit'),
      const SizedBox(height: 12),
      DosisCard(
        padding: const EdgeInsets.fromLTRB(10, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DosisBarChart(
              values: [for (final day in history.days) day.total],
              labels: [for (final day in history.days) formatDayShort(day.day)],
              reference: max,
              semanticLabel: 'Gráfico de ${history.name} nos últimos $_days dias: '
                  '${history.daysTaken} dias com registro, média de ${formatRounded(history.averagePerDayTaken)} $unit por dia.',
            ),
            if (max != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  '- - -  Limite usual por dia no catálogo: ${formatRounded(max)} $unit'
                  '${history.daysAboveReference > 0 ? '. Em laranja, os dias acima dele.' : ''}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
      if (history.kind == ProductKind.anabolic) ...[
        const SizedBox(height: 12),
        const DosisCard(
          borderColor: AppColors.orange,
          child: Row(
            children: [
              Icon(Icons.medical_services_outlined, color: AppColors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Anabolizantes não têm faixa segura sem prescrição. Leve este histórico ao seu médico.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _Stat(label: 'Total no período', value: '${formatRounded(history.total)} $unit')),
          const SizedBox(width: 10),
          Expanded(child: _Stat(label: 'Média por dia de uso', value: '${formatRounded(history.averagePerDayTaken)} $unit')),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: _Stat(label: 'Dias com registro', value: '${history.daysTaken} de $_days')),
          const SizedBox(width: 10),
          Expanded(
            child: _Stat(
              label: max == null ? 'Maior soma em um dia' : 'Dias acima do limite',
              value: max == null ? '${formatRounded(history.peak)} $unit' : '${history.daysAboveReference}',
              warn: history.daysAboveReference > 0,
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      SectionTitle('Registros', subtitle: '${history.logs.length} no período'),
      const SizedBox(height: 12),
      for (final log in visible) ...[
        StackRow(
          time: formatTime(log.takenAt),
          name: formatDay(log.takenAt.toLocal()),
          amount: formatDose(log.amount, log.unit),
        ),
        const SizedBox(height: 10),
      ],
      if (pages > 1) Pager(page: page, pages: pages, onChanged: (p) => setState(() => _page = p)),
    ];
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.warn = false});

  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return DosisCard(
      borderColor: warn ? AppColors.orange : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: warn ? AppColors.orange : Colors.white),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted))),
    );
  }
}
