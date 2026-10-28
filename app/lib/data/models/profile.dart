import 'enums.dart';
import 'json.dart';

class NotificationPreferences {
  const NotificationPreferences({required this.doseReminders, required this.symptomReminder});

  factory NotificationPreferences.fromJson(Json json) => NotificationPreferences(
        doseReminders: json['dose_reminders'] as bool? ?? true,
        symptomReminder: json['symptom_reminder'] as bool? ?? true,
      );

  /// Lembrete no horário do stack.
  final bool doseReminders;

  /// Lembrete diário "Como você está hoje?".
  final bool symptomReminder;

  Json toJson() => {'dose_reminders': doseReminders, 'symptom_reminder': symptomReminder};
}

/// Perfil (telas Perfil, Meus dados, Meu objetivo e Notificações).
class Profile {
  const Profile({
    required this.uid,
    required this.isAnonymous,
    required this.notifications,
    this.email,
    this.name,
    this.age,
    this.weightKg,
    this.heightCm,
    this.biologicalSex,
    this.goal,
    this.termsAcceptedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Json json) => Profile(
        uid: json['uid'] as String,
        isAnonymous: json['is_anonymous'] as bool,
        notifications: NotificationPreferences.fromJson(json['notifications'] as Json),
        email: json['email'] as String?,
        name: json['name'] as String?,
        age: toInt(json['age']),
        weightKg: toDouble(json['weight_kg']),
        heightCm: toDouble(json['height_cm']),
        biologicalSex: BiologicalSex.fromApi(json['biological_sex'] as String?),
        goal: Goal.fromApi(json['goal'] as String?),
        termsAcceptedAt: parseDateTime(json['terms_accepted_at']),
        createdAt: parseDateTime(json['created_at']),
        updatedAt: parseDateTime(json['updated_at']),
      );

  final String uid;
  final bool isAnonymous;
  final NotificationPreferences notifications;
  final String? email;
  final String? name;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final BiologicalSex? biologicalSex;
  final Goal? goal;
  final DateTime? termsAcceptedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
