import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';
import '../repositories/symptom_repository.dart';

/// Como foi um dia da semana, juntando todos os registros dele.
class SymptomDay {
  const SymptomDay({required this.day, required this.entries, required this.symptoms});

  /// Meia-noite do dia, no horário do aparelho.
  final DateTime day;

  /// Quantos registros foram feitos no dia.
  final int entries;

  /// Sintomas marcados no dia (vazio se só houve "Normal" ou nenhum registro).
  final Set<Symptom> symptoms;

  bool get hasEntry => entries > 0;
  bool get hasSymptoms => symptoms.isNotEmpty;
}

/// Em quantos dias da semana um sintoma apareceu, e na semana anterior.
class SymptomFrequency {
  const SymptomFrequency({required this.symptom, required this.days, required this.previousDays});

  final Symptom symptom;
  final int days;
  final int previousDays;
}

/// Relatório de uma semana (segunda a domingo).
class WeeklySymptomReport {
  const WeeklySymptomReport({
    required this.weekStart,
    required this.days,
    required this.frequencies,
    required this.entries,
    required this.previousDaysWithSymptoms,
  });

  /// Segunda-feira da semana.
  final DateTime weekStart;

  /// Os 7 dias, de segunda a domingo.
  final List<SymptomDay> days;

  /// Sintomas da semana, do mais frequente ao menos frequente.
  final List<SymptomFrequency> frequencies;

  /// Registros da semana, mais recentes primeiro (com observações).
  final List<SymptomLog> entries;

  /// Dias com sintomas na semana anterior, para comparar.
  final int previousDaysWithSymptoms;

  DateTime get weekEnd => DateTime(weekStart.year, weekStart.month, weekStart.day + 6);
  int get daysWithEntry => days.where((d) => d.hasEntry).length;
  int get daysWithSymptoms => days.where((d) => d.hasSymptoms).length;
  int get daysNormal => days.where((d) => d.hasEntry && !d.hasSymptoms).length;

  /// Diferença de dias com sintomas em relação à semana anterior (negativo = melhorou).
  int get changeFromPreviousWeek => daysWithSymptoms - previousDaysWithSymptoms;
}

/// Relatório semanal dos sintomas registrados.
class BuildWeeklySymptomReport {
  const BuildWeeklySymptomReport(this._symptoms);

  final SymptomRepository _symptoms;

  /// [weekOffset] 0 é a semana atual, -1 a anterior, e assim por diante.
  Future<WeeklySymptomReport> call({int weekOffset = 0, DateTime? now}) async {
    if (weekOffset > 0) throw ArgumentError.value(weekOffset, 'weekOffset', 'Não há relatório de semanas futuras.');

    final at = now ?? DateTime.now();
    // DateTime.weekday: segunda = 1, domingo = 7.
    final weekStart = DateTime(at.year, at.month, at.day - (at.weekday - 1) + weekOffset * 7);
    final previousStart = DateTime(weekStart.year, weekStart.month, weekStart.day - 7);
    final end = DateTime(weekStart.year, weekStart.month, weekStart.day + 7).subtract(const Duration(milliseconds: 1));

    final logs = await _symptoms.list(from: previousStart, to: end, limit: 500);

    final week = _days(weekStart, logs);
    final previous = _days(previousStart, logs);

    final frequencies = [
      for (final symptom in Symptom.values)
        SymptomFrequency(
          symptom: symptom,
          days: week.where((d) => d.symptoms.contains(symptom)).length,
          previousDays: previous.where((d) => d.symptoms.contains(symptom)).length,
        ),
    ].where((f) => f.days > 0).toList()
      ..sort((a, b) => b.days.compareTo(a.days));

    final entries = logs.where((l) {
      final local = l.loggedAt.toLocal();
      return !local.isBefore(weekStart) && !local.isAfter(end);
    }).toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    return WeeklySymptomReport(
      weekStart: weekStart,
      days: week,
      frequencies: frequencies,
      entries: entries,
      previousDaysWithSymptoms: previous.where((d) => d.hasSymptoms).length,
    );
  }

  /// Os 7 dias a partir de [start], com os registros de cada um agrupados.
  static List<SymptomDay> _days(DateTime start, List<SymptomLog> logs) => [
        for (var i = 0; i < 7; i++)
          () {
            final day = DateTime(start.year, start.month, start.day + i);
            final ofDay = logs.where((l) {
              final local = l.loggedAt.toLocal();
              return local.year == day.year && local.month == day.month && local.day == day.day;
            }).toList();
            return SymptomDay(
              day: day,
              entries: ofDay.length,
              symptoms: {
                for (final log in ofDay)
                  if (log.status == SymptomStatus.different) ...log.symptoms,
              },
            );
          }(),
      ];
}
