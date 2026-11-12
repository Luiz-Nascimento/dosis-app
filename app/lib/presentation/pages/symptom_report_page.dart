import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';
import '../../domain/usecases/build_weekly_symptom_report.dart';
import '../format.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dosis_chrome.dart';
import '../widgets/dosis_widgets.dart';
import 'symptoms_page.dart';

/// "Relatório semanal de sintomas": os 7 dias da semana, a frequência
/// de cada sintoma comparada com a semana anterior e os registros com observações.
class SymptomReportPage extends ConsumerStatefulWidget {
  const SymptomReportPage({super.key});

  @override
  ConsumerState<SymptomReportPage> createState() => _SymptomReportPageState();
}

class _SymptomReportPageState extends ConsumerState<SymptomReportPage> {
  /// 0 = semana atual, -1 = anterior...
  int _weekOffset = 0;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(symptomReportProvider(_weekOffset));

    return Scaffold(
      appBar: const DosisTopBar(),
      bottomNavigationBar: const DosisBottomNav(popToRoot: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const PageHeader('Relatório semanal'),
          ...async.when(
            loading: () => const [
              Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator())),
            ],
            error: (error, _) => [
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  'Não foi possível montar o relatório: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            ],
            data: _content,
          ),
        ],
      ),
    );
  }

  List<Widget> _content(WeeklySymptomReport report) {
    final change = report.changeFromPreviousWeek;
    final comparison = change == 0
        ? 'Igual à semana anterior'
        : '${change.abs()} ${change.abs() == 1 ? 'dia' : 'dias'} a ${change < 0 ? 'menos' : 'mais'} que na semana anterior';

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => setState(() => _weekOffset--),
            tooltip: 'Semana anterior',
            icon: const Icon(Icons.chevron_left, color: AppColors.yellow),
          ),
          Text(
            '${formatDay(report.weekStart)} a ${formatDay(report.weekEnd)}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          IconButton(
            onPressed: _weekOffset < 0 ? () => setState(() => _weekOffset++) : null,
            tooltip: 'Próxima semana',
            icon: const Icon(Icons.chevron_right, color: AppColors.yellow),
          ),
        ],
      ),
      const SizedBox(height: 8),
      DosisCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [for (final day in report.days) Expanded(child: _DayDot(day: day))],
        ),
      ),
      const SizedBox(height: 8),
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Legend(color: AppColors.orange, label: 'Com sintomas'),
          SizedBox(width: 14),
          _Legend(color: AppColors.yellow, label: 'Normal'),
          SizedBox(width: 14),
          _Legend(color: AppColors.border, label: 'Sem registro'),
        ],
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(child: _Stat(label: 'Dias com registro', value: '${report.daysWithEntry} de 7')),
          const SizedBox(width: 10),
          Expanded(
            child: _Stat(
              label: 'Dias com sintomas',
              value: '${report.daysWithSymptoms}',
              warn: report.daysWithSymptoms > 0,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(comparison, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
      const SizedBox(height: 22),
      const SectionTitle('Sintomas da semana', subtitle: 'Em quantos dias cada um apareceu'),
      const SizedBox(height: 12),
      if (report.frequencies.isEmpty)
        DosisCard(
          child: Text(
            report.daysWithEntry == 0 ? 'Nenhum registro nesta semana.' : 'Nenhum sintoma registrado nesta semana.',
            style: const TextStyle(color: AppColors.muted),
          ),
        )
      else
        DosisCard(
          child: Column(
            children: [
              for (final frequency in report.frequencies) _FrequencyRow(frequency: frequency),
            ],
          ),
        ),
      const SizedBox(height: 22),
      SectionTitle('Registros', subtitle: '${report.entries.length} na semana'),
      const SizedBox(height: 12),
      for (final entry in report.entries) ...[
        _EntryCard(entry: entry),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SymptomsPage())),
        icon: const Icon(Icons.add),
        label: const Text('Registrar como me senti'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.yellow,
          side: const BorderSide(color: AppColors.yellow),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    ];
  }
}

const _weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

class _DayDot extends StatelessWidget {
  const _DayDot({required this.day});

  final SymptomDay day;

  @override
  Widget build(BuildContext context) {
    final color = day.hasSymptoms
        ? AppColors.orange
        : day.hasEntry
            ? AppColors.yellow
            : AppColors.border;
    final state = day.hasSymptoms
        ? 'com sintomas'
        : day.hasEntry
            ? 'normal'
            : 'sem registro';
    return Semantics(
      label: '${_weekdays[day.day.weekday - 1]} ${day.day.day}: $state',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            _weekdays[day.day.weekday - 1],
            style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: day.hasEntry ? color : Colors.transparent,
              border: Border.all(color: color, width: 2),
            ),
            child: Text(
              '${day.day.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: day.hasEntry ? Colors.black : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    );
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

class _FrequencyRow extends StatelessWidget {
  const _FrequencyRow({required this.frequency});

  final SymptomFrequency frequency;

  @override
  Widget build(BuildContext context) {
    final days = frequency.days;
    final before = frequency.previousDays;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(frequency.symptom.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              Text(
                '$days ${days == 1 ? 'dia' : 'dias'}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.orange),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: days / 7,
              minHeight: 6,
              backgroundColor: AppColors.surface,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Semana anterior: $before ${before == 1 ? 'dia' : 'dias'}',
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final SymptomLog entry;

  @override
  Widget build(BuildContext context) {
    final normal = entry.status == SymptomStatus.normal;
    final note = entry.otherDescription ?? entry.notes;
    return DosisCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${formatDay(entry.loggedAt.toLocal())} · ${formatTime(entry.loggedAt)}',
            style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            normal ? 'Normal: nada de diferente' : entry.symptoms.map((s) => s.label).join(', '),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(note, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.35)),
          ],
        ],
      ),
    );
  }
}
