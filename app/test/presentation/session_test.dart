import 'package:dosis/app_dependencies.dart';
import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/models/settings.dart';
import 'package:dosis/data/models/tracking.dart';
import 'package:dosis/data/notifications/reminder_schedulers.dart';
import 'package:dosis/data/repositories/fake_article_repository.dart';
import 'package:dosis/data/repositories/fake_auth_repository.dart';
import 'package:dosis/data/repositories/fake_catalog_repository.dart';
import 'package:dosis/data/repositories/fake_repositories.dart';
import 'package:dosis/data/repositories/fake_profile_repository.dart';
import 'package:dosis/data/repositories/fake_record_edit_repository.dart';
import 'package:dosis/data/repositories/settings_repositories.dart';
import 'package:dosis/domain/repositories/routine_repository.dart';
import 'package:dosis/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rotina que devolve os itens de quem estiver "logado", como a API faz com o token.
class _RoutinePerAccount implements RoutineRepository {
  String account = 'A';

  @override
  Future<List<RoutineItem>> list({bool? active}) async => [
    RoutineItem(
      id: 'item-$account',
      name: 'Item da conta $account',
      kind: ProductKind.supplement,
      protocol: Protocol.continuous,
      doseUnit: DoseUnit.g,
      scheduleTimes: const [],
      active: true,
    ),
  ];

  @override
  Future<RoutineItem> add({
    required String productId,
    List<String>? scheduleTimes,
  }) => throw UnimplementedError();

  @override
  Future<void> remove(String id) => throw UnimplementedError();
}

void main() {
  late _RoutinePerAccount routine;
  late FakeAuthRepository auth;
  late FakeSettingsRepository settings;
  late ProviderContainer container;

  setUp(() async {
    routine = _RoutinePerAccount();
    auth = FakeAuthRepository();
    await auth.login(email: 'a@dosis.app', password: 'senha1234');
    settings = FakeSettingsRepository(
      const UserSettings(hydrationGoalMl: 3300),
    );
    final doses = FakeDoseRepository(routine);
    final symptoms = FakeSymptomRepository();
    final deps = AppDependencies(
      system: FakeSystemRepository(),
      auth: auth,
      routine: routine,
      doses: doses,
      catalog: FakeCatalogRepository(),
      articles: FakeArticleRepository(),
      symptoms: symptoms,
      edits: FakeRecordEditRepository(doses, symptoms),
      hydration: FakeHydrationRepository(),
      profile: FakeProfileRepository(),
      settings: settings,
      reminders: NoopReminderScheduler(),
    );
    container = ProviderContainer(
      overrides: [dependenciesProvider.overrideWithValue(deps)],
    );
    addTearDown(container.dispose);
  });

  Future<void> switchAccount() async {
    await container.read(sessionProvider.notifier).signOut();
    routine.account = 'B';
    await auth.login(email: 'b@dosis.app', password: 'senha1234');
    container.read(sessionProvider.notifier).signedIn();
  }

  test(
    'trocar de conta recarrega o stack em vez de mostrar o da conta anterior',
    () async {
      // Mantém o provider ouvido, como a tela faz.
      container.listen(todayStackProvider, (_, _) {});
      await container.read(sessionProvider.future);
      expect(
        (await container.read(todayStackProvider.future)).single.id,
        'item-A',
      );

      await switchAccount();

      expect(
        (await container.read(todayStackProvider.future)).single.id,
        'item-B',
      );
    },
  );

  test('a meta de água da conta anterior não passa para a próxima', () async {
    container.listen(settingsProvider, (_, _) {});
    await container.read(sessionProvider.future);
    expect(
      (await container.read(settingsProvider.future)).hydrationGoalMl,
      3300,
    );

    await switchAccount();

    expect(
      (await container.read(settingsProvider.future)).hydrationGoalMl,
      const UserSettings().hydrationGoalMl,
    );
  });
}
