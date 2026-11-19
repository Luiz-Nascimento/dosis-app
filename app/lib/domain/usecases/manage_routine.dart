import '../../data/models/tracking.dart';
import '../repositories/routine_repository.dart';

/// Regra da rotina violada. A [message] já está pronta para mostrar ao usuário.
class RoutineException implements Exception {
  const RoutineException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// "Adicionar à rotina": coloca um produto do catálogo no stack do usuário.
class AddToRoutine {
  const AddToRoutine(this._routine);

  final RoutineRepository _routine;

  Future<RoutineItem> call({required String productId, List<String>? scheduleTimes}) async {
    if (productId.trim().isEmpty) {
      throw const RoutineException('Escolha um item para adicionar.');
    }
    final current = await _routine.list();
    final existing = current.where((i) => i.productId == productId).firstOrNull;
    if (existing != null) {
      throw RoutineException('${existing.name} já está na sua rotina.');
    }
    return _routine.add(productId: productId, scheduleTimes: scheduleTimes);
  }
}

/// Lixeira de "Seus suplementos": tira o item da rotina (o histórico de doses fica).
class RemoveFromRoutine {
  const RemoveFromRoutine(this._routine);

  final RoutineRepository _routine;

  Future<void> call(String routineItemId) => _routine.remove(routineItemId);
}
