import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/models/settings.dart';
import 'package:dosis/data/models/tracking.dart';
import 'package:dosis/data/notifications/reminder_schedulers.dart';
import 'package:dosis/data/repositories/settings_repositories.dart';
import 'package:dosis/domain/repositories/routine_repository.dart';
import 'package:dosis/domain/usecases/update_settings.dart';
import 'package:flutter_test/flutter_test.dart';

class _Routine implements RoutineRepository {
  _Routine(this.items);

  final List<RoutineItem> items;

  @override
  Future<List<RoutineItem>> list({bool? active}) async => items;
}

RoutineItem _item(String name, List<String> times) => RoutineItem(
      id: name,
      name: name,
      kind: ProductKind.supplement,
      protocol: Protocol.continuous,
      doseUnit: DoseUnit.g,
      scheduleTimes: times,
      active: true,
    );

void main() {
  final items = [
    _item('Creatina', ['08:00']),
    _item('Whey Protein', ['08:00', '12:30']),
    _item('Ômega 3', const []),
  ];

  group('planReminders', () {
    test('água: um lembrete a cada intervalo, do início ao fim', () {
      const settings = UserSettings(waterReminders: true, waterIntervalHours: 3, waterStartHour: 8, waterEndHour: 20);

      final reminders = planReminders(settings, const []);

      expect(reminders.map((r) => r.hour), [8, 11, 14, 17, 20]);
      expect(reminders.every((r) => r.kind == ReminderKind.water && r.minute == 0), isTrue);
      expect(reminders.first.body, contains('2,5 L'));
      expect(reminders.map((r) => r.id).toSet(), hasLength(5));
    });

    test('suplementos: um lembrete por horário, juntando os itens do mesmo horário', () {
      const settings = UserSettings(supplementReminders: true);

      final reminders = planReminders(settings, items);

      expect(reminders, hasLength(2));
      expect((reminders[0].hour, reminders[0].minute), (8, 0));
      expect(reminders[0].body, startsWith('Creatina, Whey Protein.'));
      expect((reminders[1].hour, reminders[1].minute), (12, 30));
      expect(reminders[1].body, startsWith('Whey Protein.'));
    });

    test('tudo desligado ou horário inválido na rotina não gera lembrete', () {
      expect(planReminders(const UserSettings(), items), isEmpty);
      expect(
        planReminders(const UserSettings(supplementReminders: true), [_item('X', ['25:00', 'manhã'])]),
        isEmpty,
      );
    });
  });

  group('UpdateSettings', () {
    late FakeSettingsRepository repository;

    setUp(() => repository = FakeSettingsRepository());

    test('salva as preferências e agenda os lembretes de água e da rotina', () async {
      final scheduler = NoopReminderScheduler();
      const wanted = UserSettings(hydrationGoalMl: 3000, waterReminders: true, supplementReminders: true);

      final update = await UpdateSettings(repository, _Routine(items), scheduler)(wanted);

      expect(update.permissionDenied, isFalse);
      expect((await repository.load()).hydrationGoalMl, 3000);
      expect(scheduler.scheduled.where((r) => r.kind == ReminderKind.water), hasLength(8)); // 8h às 22h, a cada 2 h
      expect(scheduler.scheduled.where((r) => r.kind == ReminderKind.supplement), hasLength(2));
    });

    test('permissão negada: salva com os lembretes desligados e não agenda nada', () async {
      final scheduler = NoopReminderScheduler(permissionGranted: false);
      const wanted = UserSettings(hydrationGoalMl: 3000, waterReminders: true);

      final update = await UpdateSettings(repository, _Routine(items), scheduler)(wanted);

      expect(update.permissionDenied, isTrue);
      expect(update.settings.waterReminders, isFalse);
      expect(update.settings.hydrationGoalMl, 3000);
      expect(scheduler.scheduled, isEmpty);
    });

    test('desligar os lembretes cancela o que estava agendado', () async {
      final scheduler = NoopReminderScheduler();
      final update = UpdateSettings(repository, _Routine(items), scheduler);
      await update(const UserSettings(waterReminders: true));
      expect(scheduler.scheduled, isNotEmpty);

      await update(const UserSettings());

      expect(scheduler.scheduled, isEmpty);
    });

    test('recusa meta, intervalo e horários inválidos sem salvar', () async {
      final update = UpdateSettings(repository, _Routine(items), NoopReminderScheduler());

      expect(() => update(const UserSettings(hydrationGoalMl: 100)), throwsArgumentError);
      expect(() => update(const UserSettings(hydrationGoalMl: 9000)), throwsArgumentError);
      expect(() => update(const UserSettings(waterIntervalHours: 0)), throwsArgumentError);
      expect(() => update(const UserSettings(waterStartHour: 22, waterEndHour: 8)), throwsArgumentError);
      expect((await repository.load()).hydrationGoalMl, 2500);
    });
  });

  test('UserSettings vai e volta do JSON sem perder dados', () {
    const settings = UserSettings(
      hydrationGoalMl: 3300,
      waterReminders: true,
      waterIntervalHours: 3,
      waterStartHour: 7,
      waterEndHour: 21,
      supplementReminders: true,
    );

    final copy = UserSettings.fromJson(settings.toJson());

    expect(copy.toJson(), settings.toJson());
    expect(UserSettings.fromJson(const {}).hydrationGoalMl, 2500);
  });
}
