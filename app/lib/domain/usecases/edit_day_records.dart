import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';
import '../repositories/dose_repository.dart';
import '../repositories/record_edit_repository.dart';
import '../repositories/symptom_repository.dart';

/// Uma linha da tela "Editar stack do dia".
class DoseDraft {
  const DoseDraft({this.id, this.item, required this.amount, required this.takenAt});

  /// `null` quando a dose é nova.
  final String? id;

  /// Item escolhido. Em dose existente, `null` mantém o produto original.
  final RoutineItem? item;
  final double amount;
  final DateTime takenAt;
}

bool _sameMinute(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day && x.hour == y.hour && x.minute == y.minute;
}

/// Salva o "Editar stack do dia": cria as doses novas, atualiza as alteradas e
/// apaga as que saíram da lista (as exclusões vêm por último, para uma falha no
/// meio não perder dados).
class SaveDayStack {
  const SaveDayStack(this._edits, this._doses);

  final RecordEditRepository _edits;
  final DoseRepository _doses;

  Future<void> call({required List<DoseLog> original, required List<DoseDraft> drafts}) async {
    for (final draft in drafts) {
      if (draft.amount <= 0) throw ArgumentError('A dose deve ser maior que zero.');
      if (draft.id == null && draft.item == null) throw ArgumentError('Escolha o suplemento da dose nova.');
    }

    final byId = {for (final log in original) log.id: log};
    final kept = {for (final draft in drafts) if (draft.id != null) draft.id!};

    for (final draft in drafts) {
      if (draft.id == null) {
        await _doses.register(routineItemId: draft.item!.id, amount: draft.amount, takenAt: draft.takenAt);
        continue;
      }
      final old = byId[draft.id];
      if (old == null) continue;
      final itemChanged = draft.item != null && draft.item!.id != old.routineItemId;
      final changed = itemChanged || draft.amount != old.amount || !_sameMinute(draft.takenAt, old.takenAt);
      if (changed) {
        await _edits.updateDose(
          old.id,
          amount: draft.amount,
          takenAt: draft.takenAt,
          item: itemChanged ? draft.item : null,
        );
      }
    }

    for (final old in original) {
      if (!kept.contains(old.id)) await _edits.deleteDose(old.id);
    }
  }
}

/// Salva o "Editar sintomas" do dia. O dia fica com um único registro: o mais
/// recente é atualizado e os outros do mesmo dia são apagados. Sem registro,
/// cria um ao meio-dia.
class SaveDaySymptoms {
  const SaveDaySymptoms(this._edits, this._symptoms);

  final RecordEditRepository _edits;
  final SymptomRepository _symptoms;

  Future<void> call({
    required String localDate,
    required List<SymptomLog> existing,
    required SymptomStatus status,
    List<Symptom> symptoms = const [],
    String? otherDescription,
    String? notes,
  }) async {
    final chosen = status == SymptomStatus.normal ? const <Symptom>[] : symptoms.toSet().toList();
    if (status == SymptomStatus.different && chosen.isEmpty) {
      throw ArgumentError('Marque pelo menos um sintoma ou escolha "Normal".');
    }
    final hasOther = chosen.contains(Symptom.other);
    final other = otherDescription?.trim() ?? '';
    if (hasOther && other.isEmpty) throw ArgumentError('Descreva o que você sentiu.');
    final cleanOther = hasOther ? other : null;
    final cleanNotes = (notes?.trim().isEmpty ?? true) ? null : notes!.trim();

    if (existing.isEmpty) {
      final parts = localDate.split('-').map(int.parse).toList();
      await _symptoms.register(
        status: status,
        symptoms: chosen,
        otherDescription: cleanOther,
        notes: cleanNotes,
        loggedAt: DateTime(parts[0], parts[1], parts[2], 12),
      );
      return;
    }

    final sorted = [...existing]..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    await _edits.updateSymptoms(
      sorted.first.id,
      status: status,
      symptoms: chosen,
      otherDescription: cleanOther,
      notes: cleanNotes,
    );
    for (final extra in sorted.skip(1)) {
      await _edits.deleteSymptoms(extra.id);
    }
  }
}