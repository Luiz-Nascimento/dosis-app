import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/models/tracking.dart';
import 'package:dosis/domain/repositories/dose_repository.dart';
import 'package:dosis/domain/repositories/routine_repository.dart';
import 'package:dosis/domain/usecases/get_today_stack.dart';
import 'package:dosis/domain/usecases/register_dose.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDoseRepository implements DoseRepository {
  String? lastId;
  String? lastRoutineItemId;
  double? lastAmount;
  Protocol? lastProtocol;

  @override
  Future<DoseLog> register({
    String? id,
    required String routineItemId,
    double? amount,
    Protocol? protocol,
    DateTime? takenAt,
    String? notes,
  }) async {
    lastId = id;
    lastProtocol = protocol;
    lastRoutineItemId = routineItemId;
    lastAmount = amount;
    return DoseLog(
      id: 'd1',
      routineItemId: routineItemId,
      name: 'Creatina',
      kind: ProductKind.supplement,
      protocol: Protocol.continuous,
      amount: amount ?? 3,
      unit: DoseUnit.g,
      takenAt: DateTime.utc(2026, 11, 2, 12),
      localDate: '2026-11-02',
    );
  }

  @override
  Future<List<DoseLog>> list({DateTime? from, DateTime? to, String? routineItemId, int? limit}) async => const [];
}

class _FakeRoutineRepository implements RoutineRepository {
  bool? lastActive;

  @override
  Future<List<RoutineItem>> list({bool? active}) async {
    lastActive = active;
    return const [];
  }

  @override
  Future<RoutineItem> add({required String productId, List<String>? scheduleTimes}) => throw UnimplementedError();

  @override
  Future<void> remove(String id) => throw UnimplementedError();
}

void main() {
  group('RegisterDose', () {
    test('repassa o item e a dose ao repositório', () async {
      final doses = _FakeDoseRepository();

      final dose = await RegisterDose(doses)(routineItemId: 'r1', amount: 5);

      expect(doses.lastRoutineItemId, 'r1');
      expect(doses.lastAmount, 5);
      expect(dose.amount, 5);
    });

    test('repassa o id da tentativa, para o reenvio não duplicar', () async {
      final doses = _FakeDoseRepository();

      await RegisterDose(doses)(id: 'tentativa-1', routineItemId: 'r1', amount: 5);

      expect(doses.lastId, 'tentativa-1');
    });

    test('repassa o protocolo escolhido na tela', () async {
      final doses = _FakeDoseRepository();

      await RegisterDose(doses)(routineItemId: 'r1', amount: 20, protocol: Protocol.loading);

      expect(doses.lastProtocol, Protocol.loading);
    });

    test('rejeita dose zero ou negativa sem chamar o repositório', () {
      final doses = _FakeDoseRepository();

      expect(() => RegisterDose(doses)(routineItemId: 'r1', amount: 0), throwsArgumentError);
      expect(() => RegisterDose(doses)(routineItemId: 'r1', amount: -2), throwsArgumentError);
      expect(doses.lastRoutineItemId, isNull);
    });
  });

  test('GetTodayStack pede só os itens ativos', () async {
    final routine = _FakeRoutineRepository();

    await GetTodayStack(routine)();

    expect(routine.lastActive, isTrue);
  });
}