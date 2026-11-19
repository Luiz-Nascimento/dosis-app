import '../../data/models/tracking.dart';

/// Itens do stack de suplementos do usuário.
abstract interface class RoutineRepository {
  /// `active: true` devolve só o "Stack de hoje"; `null` devolve todos.
  Future<List<RoutineItem>> list({bool? active});

  /// Adiciona um produto do catálogo à rotina. Nome, tipo, unidade, dose
  /// padrão e protocolo vêm do produto.
  Future<RoutineItem> add({required String productId, List<String>? scheduleTimes});

  /// Tira o item da rotina. As doses já registradas continuam no histórico.
  Future<void> remove(String id);
}
