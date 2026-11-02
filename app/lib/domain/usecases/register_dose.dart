import '../../data/models/tracking.dart';
import '../repositories/dose_repository.dart';

/// "Registrar dose": fluxo principal do app (Abrir > Registrar Dose > Escolher suplemento e dosagem).
class RegisterDose {
  const RegisterDose(this._doses);

  final DoseRepository _doses;

  Future<DoseLog> call({
    required String routineItemId,
    double? amount,
    DateTime? takenAt,
    String? notes,
  }) {
    if (amount != null && amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'A dose deve ser maior que zero.');
    }
    return _doses.register(routineItemId: routineItemId, amount: amount, takenAt: takenAt, notes: notes);
  }
}