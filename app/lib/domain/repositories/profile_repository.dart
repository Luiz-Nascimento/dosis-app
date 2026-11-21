import '../../data/models/enums.dart';
import '../../data/models/profile.dart';

/// Perfil do usuário (Meus dados e Meu objetivo).
abstract interface class ProfileRepository {
  Future<Profile> get();

  /// Atualiza só os campos informados.
  Future<Profile> update({
    String? name,
    int? age,
    double? weightKg,
    double? heightCm,
    BiologicalSex? biologicalSex,
    Goal? goal,
  });
}