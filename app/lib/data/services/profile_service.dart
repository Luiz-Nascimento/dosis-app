import '../../core/api/api_client.dart';
import '../models/enums.dart';
import '../models/json.dart';
import '../models/profile.dart';

/// Perfil: Meus dados, Meu objetivo e Notificações (`/profile`).
class ProfileService {
  ProfileService(this.api);

  final ApiClient api;

  Future<Profile> get() async => Profile.fromJson(await api.get('/profile') as Json);

  /// Atualiza só os campos informados (idade, peso, altura e sexo ficam cifrados no servidor).
  Future<Profile> update({
    String? name,
    int? age,
    double? weightKg,
    double? heightCm,
    BiologicalSex? biologicalSex,
    Goal? goal,
    bool? doseReminders,
    bool? symptomReminder,
  }) =>
      updateFields(compact({
        'name': name,
        'age': age,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'biological_sex': biologicalSex?.apiValue,
        'goal': goal?.apiValue,
        if (doseReminders != null || symptomReminder != null)
          'notifications': compact({'dose_reminders': doseReminders, 'symptom_reminder': symptomReminder}),
      }));

  /// PATCH livre. Envie `null` para apagar um dado pessoal (ex.: `{'weight_kg': null}`).
  Future<Profile> updateFields(Map<String, Object?> fields) async =>
      Profile.fromJson(await api.patch('/profile', body: fields) as Json);
}
