import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';

/// Doses registradas pelo usuário.
abstract interface class DoseRepository {
  /// Registra uma dose de um item do stack. Se [amount], [takenAt] ou
  /// [protocol] ficarem vazios, valem a dose padrão do item, o momento atual e
  /// o protocolo do item.
  ///
  /// [id] identifica a tentativa de registro. Repetir a chamada com o mesmo
  /// [id] (ex.: depois de uma falha de rede) devolve a dose já gravada em vez
  /// de criar outra. Sem [id], o repositório gera um novo.
  Future<DoseLog> register({
    String? id,
    required String routineItemId,
    double? amount,
    Protocol? protocol,
    DateTime? takenAt,
    String? notes,
  });

  /// Mais recentes primeiro.
  Future<List<DoseLog>> list({DateTime? from, DateTime? to, String? routineItemId, int? limit});
}
