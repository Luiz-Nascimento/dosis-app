import '../../core/api/api_client.dart';
import '../models/enums.dart';
import '../models/json.dart';
import '../models/tracking.dart';
import 'collection_service.dart';

Map<String, Object?> _range(DateTime? from, DateTime? to, int? limit) => {
      'date_from': from == null ? null : isoDate(from),
      'date_to': to == null ? null : isoDate(to),
      'limit': limit,
    };

/// Itens do stack (`/routine-items`).
class RoutineService extends CollectionService<RoutineItem> {
  RoutineService(ApiClient api) : super(api, '/routine-items');

  @override
  RoutineItem fromJson(Json json) => RoutineItem.fromJson(json);

  /// `active: true` = "Stack de hoje".
  Future<List<RoutineItem>> list({bool? active, ProductKind? kind}) =>
      listWhere({'active': active, 'kind': kind?.apiValue});

  /// Do catálogo, basta o [productId]: nome, tipo, unidade e dose padrão vêm do produto.
  /// Para "Adicionar outro", informe [name], [kind] e [doseUnit].
  Future<RoutineItem> create({
    String? id,
    String? productId,
    String? name,
    String? brand,
    ProductKind? kind,
    Protocol? protocol,
    double? doseAmount,
    DoseUnit? doseUnit,
    List<String>? scheduleTimes,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    String? notes,
  }) =>
      createFrom(compact({
        'id': id,
        'product_id': productId,
        'name': name,
        'brand': brand,
        'kind': kind?.apiValue,
        'protocol': protocol?.apiValue,
        'dose_amount': doseAmount,
        'dose_unit': doseUnit?.apiValue,
        'schedule_times': scheduleTimes,
        'start_date': startDate == null ? null : isoDate(startDate),
        'end_date': endDate == null ? null : isoDate(endDate),
        'active': active,
        'notes': notes,
      }));
}

/// Doses registradas (`/doses`).
class DoseService extends CollectionService<DoseLog> {
  DoseService(ApiClient api) : super(api, '/doses');

  @override
  DoseLog fromJson(Json json) => DoseLog.fromJson(json);

  /// Mais recentes primeiro. Use [from]/[to] para o calendário e [routineItemId]
  /// para o histórico de um suplemento.
  Future<List<DoseLog>> list({DateTime? from, DateTime? to, String? routineItemId, int? limit}) =>
      listWhere({..._range(from, to, limit), 'routine_item_id': routineItemId});

  /// "Registrar dose" em 3 toques: basta o [routineItemId]. Nome, dose,
  /// unidade e protocolo vêm do item; informe [amount]/[takenAt] para mudar.
  Future<DoseLog> register({
    String? id,
    String? routineItemId,
    double? amount,
    DateTime? takenAt,
    String? notes,
    String? name,
    ProductKind? kind,
    DoseUnit? unit,
    Protocol? protocol,
  }) =>
      createFrom(compact({
        'id': id,
        'routine_item_id': routineItemId,
        'amount': amount,
        'taken_at': isoDateTime(takenAt),
        'notes': notes,
        'name': name,
        'kind': kind?.apiValue,
        'unit': unit?.apiValue,
        'protocol': protocol?.apiValue,
      }));
}

/// "Como você se sentiu?" (`/symptoms`).
class SymptomService extends CollectionService<SymptomLog> {
  SymptomService(ApiClient api) : super(api, '/symptoms');

  @override
  SymptomLog fromJson(Json json) => SymptomLog.fromJson(json);

  /// Linha do tempo, mais recentes primeiro.
  Future<List<SymptomLog>> list({DateTime? from, DateTime? to, int? limit}) => listWhere(_range(from, to, limit));

  /// `normal` exige [symptoms] vazio; `different` exige pelo menos um;
  /// `Symptom.other` exige [otherDescription].
  Future<SymptomLog> create({
    required SymptomStatus status,
    List<Symptom> symptoms = const [],
    String? otherDescription,
    String? notes,
    DateTime? loggedAt,
    String? id,
  }) =>
      createFrom(compact({
        'id': id,
        'status': status.apiValue,
        'symptoms': symptoms.map((s) => s.apiValue).toList(),
        'other_description': otherDescription,
        'notes': notes,
        'logged_at': isoDateTime(loggedAt),
      }));
}

/// Água ingerida (`/hydration`).
class HydrationService extends CollectionService<HydrationLog> {
  HydrationService(ApiClient api) : super(api, '/hydration');

  @override
  HydrationLog fromJson(Json json) => HydrationLog.fromJson(json);

  Future<List<HydrationLog>> list({DateTime? from, DateTime? to, int? limit}) => listWhere(_range(from, to, limit));

  Future<HydrationLog> create({required int amountMl, DateTime? loggedAt, String? id}) =>
      createFrom(compact({'id': id, 'amount_ml': amountMl, 'logged_at': isoDateTime(loggedAt)}));
}
