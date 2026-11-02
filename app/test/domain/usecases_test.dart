import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/models/tracking.dart';
import 'package:dosis/domain/repositories/dose_repository.dart';
import 'package:dosis/domain/repositories/routine_repository.dart';
import 'package:dosis/domain/usecases/get_today_stack.dart';
import 'package:dosis/domain/usecases/register_dose.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDoseRepository implements DoseRepository {
  String? lastRoutineItemId;
  double? lastAmount;

  @override
  Future<DoseLog> register({
    required String routineItemId,
    double? amount,
    DateTime? takenAt,
    String? notes,
  }) async {
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