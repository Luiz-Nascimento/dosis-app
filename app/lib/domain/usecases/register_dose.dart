import '../../data/models/tracking.dart';
import '../repositories/dose_repository.dart';

/// "Registrar dose": fluxo principal do app (Abrir > Registrar Dose > Escolher suplemento e dosagem).
class RegisterDose {
  const RegisterDose(this._doses);

  final DoseRepository _doses;

  /// Use o mesmo [id] ao tentar de novo a mesma dose: assim ela não é gravada duas vezes.
  Future<DoseLog> call({
    String? id,
    required String routineItemId,
    double? amount,
    DateTime? takenAt,
    String? notes,
  }) {
    if (amount != null && amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'A dose deve ser maior que zero.');
    }
    return _doses.register(id: id, routineItemId: routineItemId, amount: amount, takenAt: takenAt, notes: notes);
  }
}
