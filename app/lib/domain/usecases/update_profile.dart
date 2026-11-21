import '../../data/models/enums.dart';
import '../../data/models/profile.dart';
import '../repositories/profile_repository.dart';

/// Salva Meus dados e Meu objetivo, com os mesmos limites do backend.
class UpdateProfile {
  const UpdateProfile(this._repository);

  final ProfileRepository _repository;

  Future<Profile> call({
    String? name,
    int? age,
    double? weightKg,
    double? heightCm,
    BiologicalSex? biologicalSex,
    Goal? goal,
  }) async {
    final cleanName = name?.trim();
    if (cleanName != null && (cleanName.isEmpty || cleanName.length > 60)) {
      throw ArgumentError('O nome deve ter de 1 a 60 caracteres.');
    }
    if (age != null && (age < 10 || age > 120)) {
      throw ArgumentError('A idade deve ficar entre 10 e 120 anos.');
    }
    if (weightKg != null && (weightKg < 30 || weightKg > 300)) {
      throw ArgumentError('O peso deve ficar entre 30 e 300 kg.');
    }
    if (heightCm != null && (heightCm < 100 || heightCm > 250)) {
      throw ArgumentError('A altura deve ficar entre 100 e 250 cm.');
    }
    return _repository.update(
      name: cleanName,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
      biologicalSex: biologicalSex,
      goal: goal,
    );
  }
}