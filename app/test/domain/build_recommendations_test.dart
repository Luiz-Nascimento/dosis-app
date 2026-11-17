import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/models/recommendation.dart';
import 'package:dosis/data/models/settings.dart';
import 'package:dosis/data/models/tracking.dart';
import 'package:dosis/data/notifications/reminder_schedulers.dart';
import 'package:dosis/data/repositories/fake_catalog_repository.dart';
import 'package:dosis/data/repositories/settings_repositories.dart';
import 'package:dosis/domain/repositories/dose_repository.dart';
import 'package:dosis/domain/repositories/hydration_repository.dart';
import 'package:dosis/domain/repositories/routine_repository.dart';
import 'package:dosis/domain/repositories/symptom_repository.dart';
import 'package:dosis/domain/usecases/build_recommendations.dart';
import 'package:dosis/domain/usecases/update_settings.dart';
import 'package:flutter_test/flutter_test.dart';

class _Doses implements DoseRepository {
  _Doses([this.logs = const []]);

  final List<DoseLog> logs;

  @override
  Future<List<DoseLog>> list({DateTime? from, DateTime? to, String? routineItemId, int? limit}) async => logs;

  @override
  Future<DoseLog> register({required String routineItemId, double? amount, DateTime? takenAt, String? notes}) =>
      throw UnimplementedError();
}

class _Symptoms implements SymptomRepository {
  _Symptoms([this.logs = const []]);

  final List<SymptomLog> logs;

  @override
  Future<List<SymptomLog>> list({DateTime? from, DateTime? to, int? limit}) async => logs;

  @override
  Future<SymptomLog> register({
    required SymptomStatus status,
    List<Symptom> symptoms = const [],
    String? otherDescription,
    String? notes,
    DateTime? loggedAt,
  }) =>
      throw UnimplementedError();
}

class _Hydration implements HydrationRepository {
  _Hydration([this.logs = const []]);

  final List<HydrationLog> logs;

  @override
  Future<List<HydrationLog>> list({DateTime? from, DateTime? to, int? limit}) async => logs;

  @override
  Future<HydrationLog> log({required int amountMl, DateTime? loggedAt}) => throw UnimplementedError();

  @override
  Future<void> remove(String id) => throw UnimplementedError();
}

class _Routine implements RoutineRepository {
  _Routine([this.items = const []]);

  final List<RoutineItem> items;

  @override
  Future<List<RoutineItem>> list({bool? active}) async => items;
}

DoseLog _dose(
  String name,
  double amount,
  DateTime at, {
  String? productId,
  DoseUnit unit = DoseUnit.g,
  ProductKind kind = ProductKind.supplement,
}) =>
    DoseLog(
      id: '$name-${at.microsecondsSinceEpoch}',
      productId: productId,
      name: name,
      kind: kind,
      protocol: Protocol.continuous,
      amount: amount,
      unit: unit,
      takenAt: at,
      localDate: '',
    );

RoutineItem _item(String name, {String? productId}) => RoutineItem(
      id: name,
      productId: productId,
      name: name,
      kind: ProductKind.supplement,
      protocol: Protocol.continuous,
      doseUnit: DoseUnit.g,
      scheduleTimes: const ['08:00'],
      active: true,
    );

void main() {
  final now = DateTime(2026, 11, 12, 20);

  BuildRecommendations engine({
    List<DoseLog> doses = const [],
    List<SymptomLog> symptoms = const [],
    List<HydrationLog> hydration = const [],
    List<RoutineItem> routine = const [],
    UserSettings settings = const UserSettings(),
  }) =>
      BuildRecommendations(
        _Doses(doses),
        FakeCatalogRepository(),
        _Symptoms(symptoms),
        _Routine(routine),
        _Hydration(hydration),
        FakeSettingsRepository(settings),
      );

  test('creatina acima da faixa: avisa que 10 g não são necessários', () async {
    final result = await engine(doses: [
      _dose('Creatina', 5, DateTime(2026, 11, 12, 8), productId: 'creatina'),
      _dose('Creatina', 5, DateTime(2026, 11, 12, 12), productId: 'creatina'),
    ])(now: now);

    final recommendation = result.firstWhere((r) => r.id == 'dose-creatina');
    expect(recommendation.title, contains('10 g'));
    expect(recommendation.title, contains('Creatina'));
    expect(recommendation.level, RecommendationLevel.attention);
    expect(recommendation.sources.map((s) => s.name), contains('ISSN'));
  });

  test('anabolizante sempre pede acompanhamento médico', () async {
    final result = await engine(doses: [
      _dose('Testosterona', 100, DateTime(2026, 11, 12, 8),
          productId: 'testosterona', unit: DoseUnit.mg, kind: ProductKind.anabolic),
    ])(now: now);

    final recommendation = result.firstWhere((r) => r.id == 'anabolico-testosterona');
    expect(recommendation.level, RecommendationLevel.medical);
    expect(recommendation.sources.map((s) => s.name), containsAll(['CFM', 'SBEM']));
  });

  test('hidratação abaixo da meta à tarde vira dica', () async {
    final result = await engine(
      hydration: [
        HydrationLog(
          id: 'h1',
          amountMl: 400,
          loggedAt: DateTime(2026, 11, 12, 9),
          localDate: '2026-11-12',
        ),
      ],
      settings: const UserSettings(hydrationGoalMl: 2500),
    )(now: now);

    final recommendation = result.firstWhere((r) => r.id == 'hidratacao-baixa');
    expect(recommendation.title, contains('0,4 L'));
    expect(recommendation.sources.map((s) => s.name), contains('ACSM'));
  });

  test('palpitação registrada pede avaliação', () async {
    final result = await engine(symptoms: [
      SymptomLog(
        id: 's1',
        status: SymptomStatus.different,
        symptoms: const [Symptom.palpitation],
        loggedAt: DateTime(2026, 11, 12, 18),
        localDate: '2026-11-12',
      ),
    ])(now: now);

    expect(result.any((r) => r.id == 'sintoma-palpitacao'), isTrue);
  });

  test('sem rotina e sem registros: orienta a montar a rotina', () async {
    final result = await engine()(now: now);

    expect(result.any((r) => r.id == 'sem-rotina'), isTrue);
  });

  test('rotina sem registros: orienta a registrar as doses', () async {
    final result = await engine(routine: [_item('Creatina', productId: 'creatina')])(now: now);

    expect(result.any((r) => r.id == 'sem-registros'), isTrue);
  });

  test('dica educativa entra nos lembretes no horário escolhido', () async {
    const settings = UserSettings(educationReminders: true, educationHour: 10);
    const recommendation = Recommendation(
      id: 'dose-creatina',
      title: 'Seu corpo não precisa de 10 g de creatina',
      body: 'A faixa usual é de 3 a 5 g por dia. Ajuste a dose.',
    );

    final reminders = planReminders(settings, const [], recommendations: const [recommendation]);

    expect(reminders, hasLength(1));
    expect(reminders.single.kind, ReminderKind.education);
    expect(reminders.single.hour, 10);
    expect(reminders.single.body, 'A faixa usual é de 3 a 5 g por dia');
  });

  test('UpdateSettings agenda a dica quando o motor devolve recomendação', () async {
    final repository = FakeSettingsRepository();
    final scheduler = NoopReminderScheduler();
    final update = UpdateSettings(repository, _Routine(), scheduler, engine());

    await update(const UserSettings(educationReminders: true, educationHour: 7));

    expect(scheduler.scheduled.where((r) => r.kind == ReminderKind.education), hasLength(1));
    expect((await repository.load()).educationReminders, isTrue);
  });
}
