import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';
import '../repositories/symptom_repository.dart';

/// "Como se sente hoje?" (RF10). Valida com as mesmas regras do backend
/// (`backend/apps/tracking/serializers.py`) para o erro aparecer antes do envio.
class RegisterSymptoms {
  const RegisterSymptoms(this._symptoms);

  final SymptomRepository _symptoms;

  /// [normal]: "Não senti nada de diferente". Se [symptoms] tiver [Symptom.other],
  /// a [notes] vira a descrição do que a pessoa sentiu (o backend exige).
  Future<SymptomLog> call({
    required bool normal,
    Set<Symptom> symptoms = const {},
    String? notes,
    DateTime? loggedAt,
  }) {
    final text = notes?.trim();
    final hasText = text != null && text.isNotEmpty;

    if (normal && symptoms.isNotEmpty) {
      throw ArgumentError('Marque "Normal" ou os sintomas, não os dois.');
    }
    if (!normal && symptoms.isEmpty) {
      throw ArgumentError('Marque "Normal" ou pelo menos um sintoma.');
    }
    final other = symptoms.contains(Symptom.other);
    if (other && !hasText) {
      throw ArgumentError('Você marcou "Outro": descreva o que sentiu na observação.');
    }

    return _symptoms.register(
      status: normal ? SymptomStatus.normal : SymptomStatus.different,
      symptoms: symptoms.toList(),
      otherDescription: other ? text : null,
      notes: !other && hasText ? text : null,
      loggedAt: loggedAt,
    );
  }
}
