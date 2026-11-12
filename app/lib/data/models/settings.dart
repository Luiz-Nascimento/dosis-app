import 'json.dart';

/// Preferências guardadas no aparelho: meta de água e lembretes.
class UserSettings {
  const UserSettings({
    this.hydrationGoalMl = 2500,
    this.waterReminders = false,
    this.waterIntervalHours = 2,
    this.waterStartHour = 8,
    this.waterEndHour = 22,
    this.supplementReminders = false,
  });

  factory UserSettings.fromJson(Json json) => UserSettings(
        hydrationGoalMl: toInt(json['hydration_goal_ml']) ?? 2500,
        waterReminders: json['water_reminders'] as bool? ?? false,
        waterIntervalHours: toInt(json['water_interval_hours']) ?? 2,
        waterStartHour: toInt(json['water_start_hour']) ?? 8,
        waterEndHour: toInt(json['water_end_hour']) ?? 22,
        supplementReminders: json['supplement_reminders'] as bool? ?? false,
      );

  /// Limites aceitos para a meta diária.
  static const minGoalMl = 500;
  static const maxGoalMl = 8000;

  /// Meta diária de água, em ml.
  final int hydrationGoalMl;

  /// Lembretes de água de [waterStartHour] a [waterEndHour], a cada [waterIntervalHours] horas.
  final bool waterReminders;
  final int waterIntervalHours;
  final int waterStartHour;
  final int waterEndHour;

  /// Lembrete nos horários dos itens ativos da rotina.
  final bool supplementReminders;

  bool get anyReminder => waterReminders || supplementReminders;

  UserSettings copyWith({
    int? hydrationGoalMl,
    bool? waterReminders,
    int? waterIntervalHours,
    int? waterStartHour,
    int? waterEndHour,
    bool? supplementReminders,
  }) =>
      UserSettings(
        hydrationGoalMl: hydrationGoalMl ?? this.hydrationGoalMl,
        waterReminders: waterReminders ?? this.waterReminders,
        waterIntervalHours: waterIntervalHours ?? this.waterIntervalHours,
        waterStartHour: waterStartHour ?? this.waterStartHour,
        waterEndHour: waterEndHour ?? this.waterEndHour,
        supplementReminders: supplementReminders ?? this.supplementReminders,
      );

  Json toJson() => {
        'hydration_goal_ml': hydrationGoalMl,
        'water_reminders': waterReminders,
        'water_interval_hours': waterIntervalHours,
        'water_start_hour': waterStartHour,
        'water_end_hour': waterEndHour,
        'supplement_reminders': supplementReminders,
      };
}

enum ReminderKind { water, supplement }

/// Notificação local que se repete todo dia no mesmo horário.
class Reminder {
  const Reminder({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
  });

  /// Identifica a notificação no sistema: agendar de novo com o mesmo id substitui a anterior.
  final int id;
  final ReminderKind kind;
  final String title;
  final String body;
  final int hour;
  final int minute;
}
