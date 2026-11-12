import '../../data/models/tracking.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/settings_repository.dart';

/// Total de água de um dia.
class HydrationDay {
  const HydrationDay({required this.day, required this.totalMl});

  /// Meia-noite do dia, no horário do aparelho.
  final DateTime day;
  final int totalMl;
}

/// Meta diária de água, o que já foi bebido hoje e os últimos 7 dias.
class HydrationProgress {
  const HydrationProgress({required this.goalMl, required this.todayLogs, required this.week});

  final int goalMl;

  /// Registros de hoje, mais recentes primeiro.
  final List<HydrationLog> todayLogs;

  /// Últimos 7 dias, do mais antigo até hoje.
  final List<HydrationDay> week;

  int get consumedMl => week.last.totalMl;
  int get remainingMl => consumedMl >= goalMl ? 0 : goalMl - consumedMl;
  bool get goalReached => consumedMl >= goalMl;

  /// De 0 a 1, para a barra de progresso.
  double get fraction => goalMl <= 0 ? 0 : (consumedMl / goalMl).clamp(0, 1).toDouble();

  /// Em quantos dos últimos 7 a meta atual foi batida.
  int get daysOnGoal => week.where((d) => d.totalMl >= goalMl).length;
}

/// Progresso da meta de hidratação diária.
class GetHydrationProgress {
  const GetHydrationProgress(this._hydration, this._settings);

  final HydrationRepository _hydration;
  final SettingsRepository _settings;

  Future<HydrationProgress> call({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final today = DateTime(at.year, at.month, at.day);
    final firstDay = DateTime(today.year, today.month, today.day - 6);
    final endOfToday = DateTime(today.year, today.month, today.day + 1).subtract(const Duration(milliseconds: 1));

    final settings = await _settings.load();
    final logs = await _hydration.list(from: firstDay, to: endOfToday, limit: 500);

    final totals = <DateTime, int>{};
    final todayLogs = <HydrationLog>[];
    for (final log in logs) {
      final local = log.loggedAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day.isBefore(firstDay) || day.isAfter(today)) continue;
      totals[day] = (totals[day] ?? 0) + log.amountMl;
      if (day == today) todayLogs.add(log);
    }
    todayLogs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    return HydrationProgress(
      goalMl: settings.hydrationGoalMl,
      todayLogs: todayLogs,
      week: [
        for (var i = 0; i < 7; i++)
          () {
            final day = DateTime(firstDay.year, firstDay.month, firstDay.day + i);
            return HydrationDay(day: day, totalMl: totals[day] ?? 0);
          }(),
      ],
    );
  }
}

/// Registra água ingerida. Mesmo limite do backend: de 1 a 5000 ml por registro.
class LogWater {
  const LogWater(this._hydration);

  final HydrationRepository _hydration;

  Future<HydrationLog> call(int amountMl, {DateTime? loggedAt}) {
    if (amountMl < 1 || amountMl > 5000) {
      throw ArgumentError('Informe uma quantidade entre 1 e 5000 ml.');
    }
    return _hydration.log(amountMl: amountMl, loggedAt: loggedAt);
  }
}

/// Apaga um registro de água feito por engano.
class RemoveWaterLog {
  const RemoveWaterLog(this._hydration);

  final HydrationRepository _hydration;

  Future<void> call(String id) => _hydration.remove(id);
}
