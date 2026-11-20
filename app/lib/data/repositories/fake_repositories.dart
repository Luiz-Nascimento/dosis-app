import '../../core/ids.dart';
import '../../domain/repositories/dose_repository.dart';
import '../../domain/repositories/hydration_repository.dart';
import '../../domain/repositories/routine_repository.dart';
import '../../domain/repositories/symptom_repository.dart';
import '../../domain/repositories/system_repository.dart';
import '../models/auth.dart';
import '../models/enums.dart';
import '../models/tracking.dart';
import 'fake_catalog_repository.dart';

class FakeSystemRepository implements SystemRepository {
  @override
  Future<HealthStatus> health() async => const HealthStatus(status: 'ok', firebaseMode: 'mock');
}

class FakeRoutineRepository implements RoutineRepository {
  /// Começa com creatina e whey para o app ter o que mostrar sem backend.
  final List<RoutineItem> _items = [
    const RoutineItem(
      id: 'r-creatina',
      productId: 'creatina',
      name: 'Creatina',
      brand: 'Growth',
      kind: ProductKind.supplement,
      protocol: Protocol.continuous,
      doseAmount: 5,
      doseUnit: DoseUnit.g,
      scheduleTimes: ['08:00'],
      active: true,
    ),
    const RoutineItem(
      id: 'r-whey',
      productId: 'whey-protein',
      name: 'Whey Protein',
      brand: 'Growth',
      kind: ProductKind.supplement,
      protocol: Protocol.continuous,
      doseAmount: 60,
      doseUnit: DoseUnit.g,
      scheduleTimes: ['12:30'],
      active: true,
    ),
  ];

  @override
  Future<List<RoutineItem>> list({bool? active}) async =>
      List.unmodifiable(active == null ? _items : _items.where((i) => i.active == active));

  /// Completa o item com os dados do catálogo, como o backend faz.
  @override
  Future<RoutineItem> add({required String productId, List<String>? scheduleTimes}) async {
    final product = FakeCatalogRepository.products.where((p) => p.id == productId).firstOrNull;
    if (product == null) throw ArgumentError.value(productId, 'productId', 'Produto não encontrado no catálogo.');
    final item = RoutineItem(
      id: newId(),
      productId: product.id,
      name: product.name,
      kind: product.kind,
      protocol: Protocol.continuous,
      doseAmount: product.defaultDose,
      doseUnit: product.defaultUnit,
      scheduleTimes: [...?scheduleTimes]..sort(),
      active: true,
    );
    _items.add(item);
    return item;
  }

  @override
  Future<void> remove(String id) async => _items.removeWhere((i) => i.id == id);
}

class FakeDoseRepository implements DoseRepository {
  FakeDoseRepository(this._routine);

  final RoutineRepository _routine;
  late final List<DoseLog> _logs = _seed();

  List<DoseLog> _seed() {
    final now = DateTime.now();
    final logs = <DoseLog>[];
    for (var back = 1; back <= 7; back++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: back));
      logs.add(_log('Creatina', 5, DateTime(day.year, day.month, day.day, 8), routineItemId: 'r-creatina', productId: 'creatina'));
      logs.add(_log('Whey Protein', 60, DateTime(day.year, day.month, day.day, 12, 30),
          routineItemId: 'r-whey', productId: 'whey-protein'));
    }
    return logs;
  }

  DoseLog _log(String name, double amount, DateTime at, {String? routineItemId, String? productId}) => DoseLog(
        id: newId(),
        routineItemId: routineItemId,
        productId: productId,
        name: name,
        kind: ProductKind.supplement,
        protocol: Protocol.continuous,
        amount: amount,
        unit: DoseUnit.g,
        takenAt: at,
        localDate: _date(at),
      );

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<DoseLog> register({
    String? id,
    required String routineItemId,
    double? amount,
    Protocol? protocol,
    DateTime? takenAt,
    String? notes,
  }) async {
    // Mesmo comportamento da API: repetir o id devolve a dose já gravada.
    final existing = id == null ? null : _logs.where((l) => l.id == id).firstOrNull;
    if (existing != null) return existing;

    final item = (await _routine.list()).firstWhere((i) => i.id == routineItemId);
    final log = DoseLog(
      id: id ?? newId(),
      routineItemId: item.id,
      productId: item.productId,
      name: item.name,
      kind: item.kind,
      protocol: protocol ?? item.protocol,
      amount: amount ?? item.doseAmount ?? 0,
      unit: item.doseUnit,
      takenAt: takenAt ?? DateTime.now(),
      localDate: _date(takenAt ?? DateTime.now()),
      notes: notes,
    );
    _logs.add(log);
    return log;
  }

  @override
  Future<List<DoseLog>> list({DateTime? from, DateTime? to, String? routineItemId, int? limit}) async {
    var result = _logs.where((l) {
      if (from != null && l.takenAt.isBefore(from)) return false;
      if (to != null && l.takenAt.isAfter(to)) return false;
      if (routineItemId != null && l.routineItemId != routineItemId) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
    if (limit != null && result.length > limit) result = result.sublist(0, limit);
    return result;
  }
}

class FakeSymptomRepository implements SymptomRepository {
  /// Com [seeded], começa com registros de exemplo das duas últimas semanas,
  /// para o painel de risco e o relatório semanal terem o que mostrar.
  FakeSymptomRepository({bool seeded = false}) {
    if (!seeded) return;
    final now = DateTime.now();
    SymptomLog at(int daysAgo, int hour, List<Symptom> symptoms, {String? notes}) {
      final when = DateTime(now.year, now.month, now.day - daysAgo, hour);
      return SymptomLog(
        id: newId(),
        status: symptoms.isEmpty ? SymptomStatus.normal : SymptomStatus.different,
        symptoms: symptoms,
        notes: notes,
        loggedAt: when,
        localDate: FakeDoseRepository._date(when),
      );
    }

    _logs.addAll([
      at(1, 21, [Symptom.nausea], notes: 'Depois do pré-treino em jejum'),
      at(2, 20, const []),
      at(4, 22, [Symptom.fatigue, Symptom.dizziness]),
      at(5, 20, const []),
      at(8, 21, [Symptom.nausea]),
      at(10, 20, const []),
    ]);
  }

  final List<SymptomLog> _logs = [];

  @override
  Future<SymptomLog> register({
    required SymptomStatus status,
    List<Symptom> symptoms = const [],
    String? otherDescription,
    String? notes,
    DateTime? loggedAt,
  }) async {
    final at = loggedAt ?? DateTime.now();
    final log = SymptomLog(
      id: newId(),
      status: status,
      symptoms: symptoms,
      otherDescription: otherDescription,
      notes: notes,
      loggedAt: at,
      localDate: FakeDoseRepository._date(at),
    );
    _logs.add(log);
    return log;
  }

  @override
  Future<List<SymptomLog>> list({DateTime? from, DateTime? to, int? limit}) async {
    var result = _logs.where((l) {
      if (from != null && l.loggedAt.isBefore(from)) return false;
      if (to != null && l.loggedAt.isAfter(to)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    if (limit != null && result.length > limit) result = result.sublist(0, limit);
    return result;
  }
}

class FakeHydrationRepository implements HydrationRepository {
  final List<HydrationLog> _logs = [];

  @override
  Future<HydrationLog> log({required int amountMl, DateTime? loggedAt}) async {
    final at = loggedAt ?? DateTime.now();
    final log = HydrationLog(id: newId(), amountMl: amountMl, loggedAt: at, localDate: FakeDoseRepository._date(at));
    _logs.add(log);
    return log;
  }

  @override
  Future<List<HydrationLog>> list({DateTime? from, DateTime? to, int? limit}) async {
    var result = _logs.where((l) {
      if (from != null && l.loggedAt.isBefore(from)) return false;
      if (to != null && l.loggedAt.isAfter(to)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    if (limit != null && result.length > limit) result = result.sublist(0, limit);
    return result;
  }

  @override
  Future<void> remove(String id) async => _logs.removeWhere((l) => l.id == id);
}
