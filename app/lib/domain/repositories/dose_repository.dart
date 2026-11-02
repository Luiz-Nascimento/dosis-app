import '../../data/models/tracking.dart';

/// Doses registradas pelo usuário.
abstract interface class DoseRepository {
  /// Registra uma dose de um item do stack. Se [amount] ou [takenAt] ficarem
  /// vazios, valem a dose padrão do item e o momento atual.
  Future<DoseLog> register({
    required String routineItemId,
    double? amount,
    DateTime? takenAt,
    String? notes,
  });

  /// Mais recentes primeiro.
  Future<List<DoseLog>> list({DateTime? from, DateTime? to, String? routineItemId, int? limit});
}