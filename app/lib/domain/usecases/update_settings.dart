import '../../data/models/settings.dart';
import '../../data/models/tracking.dart';
import '../repositories/reminder_scheduler.dart';
import '../repositories/routine_repository.dart';
import '../repositories/settings_repository.dart';

/// Resultado de salvar as preferências.
class SettingsUpdate {
  const SettingsUpdate({required this.settings, required this.permissionDenied});

  /// O que ficou salvo de fato.
  final UserSettings settings;

  /// O usuário pediu lembretes mas negou a permissão de notificações:
  /// as preferências foram salvas com os lembretes desligados.
  final bool permissionDenied;
}

/// Monta os lembretes diários a partir das preferências e dos itens ativos da rotina.
///
/// * Água: um lembrete a cada [UserSettings.waterIntervalHours] horas, do
///   horário inicial ao final (ex.: 8h, 10h, ..., 22h).
/// * Suplementos: um lembrete por horário da rotina, juntando os itens do mesmo horário.
List<Reminder> planReminders(UserSettings settings, List<RoutineItem> activeItems) {
  final reminders = <Reminder>[];

  if (settings.waterReminders) {
    final liters = (settings.hydrationGoalMl / 1000).toStringAsFixed(1).replaceAll('.', ',');
    for (var hour = settings.waterStartHour; hour <= settings.waterEndHour; hour += settings.waterIntervalHours) {
      reminders.add(Reminder(
        id: 1000 + hour,
        kind: ReminderKind.water,
        title: 'Hora de beber água',
        body: 'Sua meta de hoje é $liters L. Registre no Dosis o que você beber.',
        hour: hour,
        minute: 0,
      ));
    }
  }

  if (settings.supplementReminders) {
    final byTime = <int, List<String>>{};
    for (final item in activeItems) {
      for (final time in item.scheduleTimes) {
        final parts = time.split(':');
        final hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
        final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
        if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) continue;
        final names = byTime.putIfAbsent(hour * 60 + minute, () => []);
        if (!names.contains(item.name)) names.add(item.name);
      }
    }
    for (final minutes in byTime.keys.toList()..sort()) {
      reminders.add(Reminder(
        id: 2000 + minutes,
        kind: ReminderKind.supplement,
        title: 'Hora do seu stack',
        body: '${byTime[minutes]!.join(', ')}. Toque para registrar a dose.',
        hour: minutes ~/ 60,
        minute: minutes % 60,
      ));
    }
  }

  return reminders;
}

/// Salva a meta de água e os lembretes e reagenda as notificações.
class UpdateSettings {
  const UpdateSettings(this._settings, this._routine, this._scheduler);

  final SettingsRepository _settings;
  final RoutineRepository _routine;
  final ReminderScheduler _scheduler;

  Future<SettingsUpdate> call(UserSettings wanted) async {
    if (wanted.hydrationGoalMl < UserSettings.minGoalMl || wanted.hydrationGoalMl > UserSettings.maxGoalMl) {
      throw ArgumentError('A meta deve ficar entre 0,5 e 8 litros por dia.');
    }
    if (wanted.waterIntervalHours < 1 || wanted.waterIntervalHours > 12) {
      throw ArgumentError('O intervalo dos lembretes deve ser de 1 a 12 horas.');
    }
    if (wanted.waterStartHour < 0 || wanted.waterEndHour > 23 || wanted.waterStartHour > wanted.waterEndHour) {
      throw ArgumentError('O horário inicial dos lembretes deve vir antes do final.');
    }

    var settings = wanted;
    var denied = false;
    if (settings.anyReminder && !await _scheduler.requestPermission()) {
      settings = settings.copyWith(waterReminders: false, supplementReminders: false);
      denied = true;
    }

    final items = settings.supplementReminders ? await _routine.list(active: true) : const <RoutineItem>[];
    await _scheduler.replaceAll(planReminders(settings, items));
    await _settings.save(settings);
    return SettingsUpdate(settings: settings, permissionDenied: denied);
  }
}
