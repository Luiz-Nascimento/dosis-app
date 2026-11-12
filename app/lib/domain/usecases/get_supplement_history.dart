import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/dose_repository.dart';
import 'check_dose_safety.dart' show convertDose;

/// Soma das doses de um suplemento em um dia (um ponto do gráfico).
class DailyDose {
  const DailyDose({required this.day, required this.total, required this.count});

  /// Meia-noite do dia, no horário do aparelho.
  final DateTime day;

  /// Soma do dia na unidade do histórico. Zero quando não houve registro.
  final double total;

  /// Quantas doses foram registradas no dia.
  final int count;
}

/// Histórico de um suplemento em um período: registros, série diária e resumo.
class SupplementHistory {
  const SupplementHistory({
    required this.key,
    required this.name,
    required this.kind,
    required this.unit,
    required this.logs,
    required this.days,
    this.referenceMin,
    this.referenceMax,
  });

  /// Id do produto no catálogo ou, para itens cadastrados à mão, o nome.
  final String key;
  final String name;
  final ProductKind kind;

  /// Unidade em que os totais estão (a do registro mais recente).
  final DoseUnit unit;

  /// Registros do período, mais recentes primeiro.
  final List<DoseLog> logs;

  /// Um item por dia do período, do mais antigo ao mais recente, inclusive dias sem dose.
  final List<DailyDose> days;

  /// Faixa usual por dia do catálogo, na [unit]. Só existe para produtos com
  /// faixa diária (ex.: creatina); anabolizantes e faixas por tomada não têm.
  final double? referenceMin;
  final double? referenceMax;

  double get total => days.fold(0, (sum, d) => sum + d.total);
  int get daysTaken => days.where((d) => d.count > 0).length;
  double get peak => days.fold(0, (max, d) => d.total > max ? d.total : max);

  /// Média considerando só os dias em que houve registro.
  double get averagePerDayTaken => daysTaken == 0 ? 0 : total / daysTaken;

  /// Dias em que a soma passou do limite usual do catálogo.
  int get daysAboveReference =>
      referenceMax == null ? 0 : days.where((d) => d.total > referenceMax! + 1e-9).length;

  DateTime? get lastTakenAt => logs.isEmpty ? null : logs.first.takenAt;
}

/// Histórico de consumo por suplemento e a evolução das doses dia a dia.
class GetSupplementHistory {
  const GetSupplementHistory(this._doses, this._catalog);

  final DoseRepository _doses;
  final CatalogRepository _catalog;

  /// Histórico dos últimos [days] dias (contando hoje), um por suplemento,
  /// começando pelo usado mais recentemente.
  Future<List<SupplementHistory>> call({int days = 30, DateTime? now}) async {
    if (days <= 0) throw ArgumentError.value(days, 'days', 'O período deve ter pelo menos um dia.');

    final today = now ?? DateTime.now();
    final lastDay = DateTime(today.year, today.month, today.day);
    final firstDay = DateTime(lastDay.year, lastDay.month, lastDay.day - (days - 1));
    final endOfLastDay = DateTime(lastDay.year, lastDay.month, lastDay.day + 1).subtract(const Duration(milliseconds: 1));

    // 500 é o máximo que a API devolve por chamada.
    final logs = await _doses.list(from: firstDay, to: endOfLastDay, limit: 500);

    final groups = <String, List<DoseLog>>{};
    for (final log in logs) {
      final at = log.takenAt.toLocal();
      if (at.isBefore(firstDay) || at.isAfter(endOfLastDay)) continue;
      groups.putIfAbsent(log.productId ?? log.name.trim().toLowerCase(), () => []).add(log);
    }

    final result = <SupplementHistory>[];
    for (final entry in groups.entries) {
      final sorted = entry.value..sort((a, b) => b.takenAt.compareTo(a.takenAt));
      final latest = sorted.first;
      final unit = latest.unit;

      final totals = <DateTime, double>{};
      final counts = <DateTime, int>{};
      for (final log in sorted) {
        final at = log.takenAt.toLocal();
        final day = DateTime(at.year, at.month, at.day);
        // Registros em unidade que não se converte (ex.: cápsulas x g) entram pelo valor informado.
        totals[day] = (totals[day] ?? 0) + (convertDose(log.amount, log.unit, unit) ?? log.amount);
        counts[day] = (counts[day] ?? 0) + 1;
      }

      final (min, max) = await _reference(latest, unit);
      result.add(SupplementHistory(
        key: entry.key,
        name: latest.name,
        kind: latest.kind,
        unit: unit,
        logs: sorted,
        days: [
          for (var i = 0; i < days; i++)
            () {
              final day = DateTime(firstDay.year, firstDay.month, firstDay.day + i);
              return DailyDose(day: day, total: totals[day] ?? 0, count: counts[day] ?? 0);
            }(),
        ],
        referenceMin: min,
        referenceMax: max,
      ));
    }

    result.sort((a, b) => b.lastTakenAt!.compareTo(a.lastTakenAt!));
    return result;
  }

  /// Faixa diária do catálogo para o protocolo do registro mais recente, na [unit].
  Future<(double?, double?)> _reference(DoseLog latest, DoseUnit unit) async {
    final productId = latest.productId;
    if (productId == null) return (null, null);
    try {
      final range = (await _catalog.productById(productId))?.rangeFor(latest.protocol);
      if (range == null || range.per != 'day') return (null, null);
      return (convertDose(range.min, range.unit, unit), convertDose(range.max, range.unit, unit));
    } catch (_) {
      // Sem catálogo (ex.: offline) o histórico aparece sem a linha de referência.
      return (null, null);
    }
  }
}
