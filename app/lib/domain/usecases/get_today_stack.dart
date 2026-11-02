import '../../data/models/tracking.dart';
import '../repositories/routine_repository.dart';

/// Itens do stack ativos hoje, base da lista de suplementos e do "Registrar dose".
class GetTodayStack {
  const GetTodayStack(this._routine);

  final RoutineRepository _routine;

  Future<List<RoutineItem>> call() => _routine.list(active: true);
}