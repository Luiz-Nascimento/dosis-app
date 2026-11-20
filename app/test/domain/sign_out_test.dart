import 'package:dosis/data/models/settings.dart';
import 'package:dosis/data/notifications/reminder_schedulers.dart';
import 'package:dosis/data/repositories/fake_auth_repository.dart';
import 'package:dosis/data/repositories/settings_repositories.dart';
import 'package:dosis/domain/repositories/reminder_scheduler.dart';
import 'package:dosis/domain/usecases/sign_out.dart';
import 'package:flutter_test/flutter_test.dart';

const _reminder = Reminder(
  id: 1,
  kind: ReminderKind.supplement,
  title: 'Creatina',
  body: 'Hora da sua dose de creatina.',
  hour: 8,
  minute: 0,
);

class _BrokenScheduler implements ReminderScheduler {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> replaceAll(List<Reminder> reminders) async => throw Exception('plugin indisponível');
}

void main() {
  group('SignOut', () {
    test('encerra a sessão, cancela os lembretes e volta as preferências ao padrão', () async {
      final auth = FakeAuthRepository();
      await auth.login(email: 'a@dosis.app', password: 'senha1234');
      final settings = FakeSettingsRepository(
        const UserSettings(hydrationGoalMl: 3300, supplementReminders: true),
      );
      final reminders = NoopReminderScheduler()..scheduled = const [_reminder];

      await SignOut(auth, settings, reminders)();

      expect(await auth.isSignedIn(), isFalse);
      expect(reminders.scheduled, isEmpty);
      final cleared = await settings.load();
      expect(cleared.hydrationGoalMl, const UserSettings().hydrationGoalMl);
      expect(cleared.supplementReminders, isFalse);
    });

    test('falha ao cancelar lembretes não impede sair nem limpar as preferências', () async {
      final auth = FakeAuthRepository();
      await auth.login(email: 'a@dosis.app', password: 'senha1234');
      final settings = FakeSettingsRepository(const UserSettings(hydrationGoalMl: 3300));

      await SignOut(auth, settings, _BrokenScheduler())();

      expect(await auth.isSignedIn(), isFalse);
      expect((await settings.load()).hydrationGoalMl, const UserSettings().hydrationGoalMl);
    });
  });
}
