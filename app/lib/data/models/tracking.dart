import 'enums.dart';
import 'json.dart';

/// Item do stack (`/tracking/routine-items/`): "Seus itens" e "Stack de hoje".
class RoutineItem {
  const RoutineItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.protocol,
    required this.doseUnit,
    required this.scheduleTimes,
    required this.active,
    this.productId,
    this.brand,
    this.doseAmount,
    this.startDate,
    this.endDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory RoutineItem.fromJson(Json json) => RoutineItem(
        id: json['id'] as String,
        productId: json['product_id'] as String?,
        name: json['name'] as String,
        brand: json['brand'] as String?,
        kind: ProductKind.fromApi(json['kind'] as String?),
        protocol: Protocol.fromApi(json['protocol'] as String?),
        doseAmount: toDouble(json['dose_amount']),
        doseUnit: DoseUnit.fromApi(json['dose_unit'] as String?),
        scheduleTimes: stringList(json['schedule_times']),
        startDate: json['start_date'] as String?,
        endDate: json['end_date'] as String?,
        active: json['active'] as bool? ?? true,
        notes: json['notes'] as String?,
        createdAt: parseDateTime(json['created_at']),
        updatedAt: parseDateTime(json['updated_at']),
      );

  final String id;
  final String? productId;
  final String name;
  final String? brand;
  final ProductKind kind;
  final Protocol protocol;
  final double? doseAmount;
  final DoseUnit doseUnit;

  /// Horários no formato HH:MM.
  final List<String> scheduleTimes;

  /// Datas no formato AAAA-MM-DD.
  final String? startDate;
  final String? endDate;
  final bool active;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

/// Dose registrada (`/tracking/doses/`).
class DoseLog {
  const DoseLog({
    required this.id,
    required this.name,
    required this.kind,
    required this.protocol,
    required this.amount,
    required this.unit,
    required this.takenAt,
    required this.localDate,
    this.routineItemId,
    this.productId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory DoseLog.fromJson(Json json) => DoseLog(
        id: json['id'] as String,
        routineItemId: json['routine_item_id'] as String?,
        productId: json['product_id'] as String?,
        name: json['name'] as String,
        kind: ProductKind.fromApi(json['kind'] as String?),
        protocol: Protocol.fromApi(json['protocol'] as String?),
        amount: toDouble(json['amount'])!,
        unit: DoseUnit.fromApi(json['unit'] as String?),
        takenAt: parseDateTime(json['taken_at'])!,
        localDate: json['local_date'] as String,
        notes: json['notes'] as String?,
        createdAt: parseDateTime(json['created_at']),
        updatedAt: parseDateTime(json['updated_at']),
      );

  final String id;
  final String? routineItemId;
  final String? productId;
  final String name;
  final ProductKind kind;
  final Protocol protocol;
  final double amount;
  final DoseUnit unit;
  final DateTime takenAt;

  /// Dia do calendário (AAAA-MM-DD, fuso de Brasília).
  final String localDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

/// "Como você se sentiu?" (`/tracking/symptoms/`).
class SymptomLog {
  const SymptomLog({
    required this.id,
    required this.status,
    required this.symptoms,
    required this.loggedAt,
    required this.localDate,
    this.otherDescription,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory SymptomLog.fromJson(Json json) => SymptomLog(
        id: json['id'] as String,
        status: SymptomStatus.fromApi(json['status'] as String?),
        symptoms: stringList(json['symptoms']).map(Symptom.fromApi).toList(),
        otherDescription: json['other_description'] as String?,
        notes: json['notes'] as String?,
        loggedAt: parseDateTime(json['logged_at'])!,
        localDate: json['local_date'] as String,
        createdAt: parseDateTime(json['created_at']),
        updatedAt: parseDateTime(json['updated_at']),
      );

  final String id;
  final SymptomStatus status;
  final List<Symptom> symptoms;
  final String? otherDescription;
  final String? notes;
  final DateTime loggedAt;
  final String localDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

/// Água ingerida (`/tracking/hydration/`).
class HydrationLog {
  const HydrationLog({
    required this.id,
    required this.amountMl,
    required this.loggedAt,
    required this.localDate,
    this.createdAt,
    this.updatedAt,
  });

  factory HydrationLog.fromJson(Json json) => HydrationLog(
        id: json['id'] as String,
        amountMl: json['amount_ml'] as int,
        loggedAt: parseDateTime(json['logged_at'])!,
        localDate: json['local_date'] as String,
        createdAt: parseDateTime(json['created_at']),
        updatedAt: parseDateTime(json['updated_at']),
      );

  final String id;
  final int amountMl;
  final DateTime loggedAt;
  final String localDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
