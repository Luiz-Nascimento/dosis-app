import '../../data/models/tracking.dart';
import '../repositories/dose_repository.dart';

/// Histórico de doses (tela "Registros").
class GetDoseHistory {
  const GetDoseHistory(this._doses);

  final DoseRepository _doses;

  Future<List<DoseLog>> call({DateTime? from, DateTime? to, int? limit}) =>
      _doses.list(from: from, to: to, limit: limit);
}