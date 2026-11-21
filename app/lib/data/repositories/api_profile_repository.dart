import '../../domain/repositories/profile_repository.dart';
import '../models/enums.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';

/// Perfil guardado na API (`/profile/`).
class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._service);

  final ProfileService _service;

  @override
  Future<Profile> get() => _service.get();

  @override
  Future<Profile> update({
    String? name,
    int? age,
    double? weightKg,
    double? heightCm,
    BiologicalSex? biologicalSex,
    Goal? goal,
  }) =>
      _service.update(
        name: name,
        age: age,
        weightKg: weightKg,
        heightCm: heightCm,
        biologicalSex: biologicalSex,
        goal: goal,
      );
}