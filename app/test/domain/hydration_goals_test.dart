import 'package:dosis/data/models/settings.dart';
import 'package:dosis/data/repositories/fake_repositories.dart';
import 'package:dosis/data/repositories/settings_repositories.dart';
import 'package:dosis/domain/usecases/hydration_goals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 12, 20);
  late FakeHydrationRepository hydration;
  late FakeSettingsRepository settings;

  setUp(() {
    hydration = FakeHydrationRepository();
    settings = FakeSettingsRepository(const UserSettings(hydrationGoalMl: 2000));
  });

  Future<HydrationProgress> progress() => GetHydrationProgress(hydration, settings)(now: now);

  test('sem registros: nada bebido e a meta inteira faltando', () async {
    final result = await progress();

    expect(result.goalMl, 2000);
    expect(result.consumedMl, 0);
    expect(result.remainingMl, 2000);
    expect(result.fraction, 0);
    expect(result.goalReached, isFalse);
    expect(result.week, hasLength(7));
    expect(result.week.first.day, DateTime(2026, 11, 6));
    expect(result.week.last.day, DateTime(2026, 11, 12));
  });

  test('soma os registros de hoje e lista do mais recente para o mais antigo', () async {
    await hydration.log(amountMl: 300, loggedAt: DateTime(2026, 11, 12, 8));
    await hydration.log(amountMl: 500, loggedAt: DateTime(2026, 11, 12, 15));

    final result = await progress();

    expect(result.consumedMl, 800);
    expect(result.remainingMl, 1200);
    expect(result.fraction, 0.4);
    expect(result.todayLogs.map((l) => l.amountMl), [500, 300]);
  });

  test('passar da meta: marca como batida, sem faltar nada e com a barra cheia', () async {
    await hydration.log(amountMl: 2500, loggedAt: DateTime(2026, 11, 12, 9));

    final result = await progress();

    expect(result.goalReached, isTrue);
    expect(result.remainingMl, 0);
    expect(result.fraction, 1);
  });

  test('separa os últimos 7 dias, conta os dias com meta batida e ignora dias mais antigos', () async {
    await hydration.log(amountMl: 2000, loggedAt: DateTime(2026, 11, 11, 10)); // ontem: bateu
    await hydration.log(amountMl: 1000, loggedAt: DateTime(2026, 11, 10, 10)); // anteontem: não bateu
    await hydration.log(amountMl: 3000, loggedAt: DateTime(2026, 11, 5, 10)); // fora dos 7 dias

    final result = await progress();

    expect(result.week[5].totalMl, 2000);
    expect(result.week[4].totalMl, 1000);
    expect(result.daysOnGoal, 1);
    expect(result.consumedMl, 0);
  });

  test('LogWater recusa quantidades fora de 1 a 5000 ml sem gravar', () async {
    final log = LogWater(hydration);

    expect(() => log(0), throwsArgumentError);
    expect(() => log(5001), throwsArgumentError);
    expect(await hydration.list(), isEmpty);

    await log(250);
    expect((await hydration.list()).single.amountMl, 250);
  });

  test('RemoveWaterLog apaga o registro', () async {
    final entry = await LogWater(hydration)(250);

    await RemoveWaterLog(hydration)(entry.id);

    expect(await hydration.list(), isEmpty);
  });
}
