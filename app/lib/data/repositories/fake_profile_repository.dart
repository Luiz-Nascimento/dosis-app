import '../../domain/repositories/profile_repository.dart';
import '../models/enums.dart';
import '../models/profile.dart';

/// Perfil em memória, para `USE_API=false` e para os testes.
class FakeProfileRepository implements ProfileRepository {
  Profile _profile = const Profile(
    uid: 'fake',
    isAnonymous: false,
    notifications: NotificationPreferences(doseReminders: true, symptomReminder: true),
  );

  @override
  Future<Profile> get() async => _profile;

  @override
  Future<Profile> update({
    String? name,
    int? age,
    double? weightKg,
    double? heightCm,
    BiologicalSex? biologicalSex,
    Goal? goal,
  }) async {
    final p = _profile;
    return _profile = Profile(
      uid: p.uid,
      isAnonymous: p.isAnonymous,
      notifications: p.notifications,
      email: p.email,
      name: name ?? p.name,
      age: age ?? p.age,
      weightKg: weightKg ?? p.weightKg,
      heightCm: heightCm ?? p.heightCm,
      biologicalSex: biologicalSex ?? p.biologicalSex,
      goal: goal ?? p.goal,
      termsAcceptedAt: p.termsAcceptedAt,
      createdAt: p.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}