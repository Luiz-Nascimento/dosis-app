import '../../data/models/tracking.dart';

/// Água ingerida, registrada pelo usuário.
abstract interface class HydrationRepository {
  Future<HydrationLog> log({required int amountMl, DateTime? loggedAt});

  /// Mais recentes primeiro.
  Future<List<HydrationLog>> list({DateTime? from, DateTime? to, int? limit});

  Future<void> remove(String id);
}
