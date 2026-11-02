import '../../data/models/tracking.dart';

/// Itens do stack de suplementos do usuário.
abstract interface class RoutineRepository {
  /// `active: true` devolve só o "Stack de hoje"; `null` devolve todos.
  Future<List<RoutineItem>> list({bool? active});
}