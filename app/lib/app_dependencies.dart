import 'package:flutter/foundation.dart';

import 'data/dosis_api.dart';
import 'data/notifications/reminder_schedulers.dart';
import 'data/repositories/api_auth_repository.dart';
import 'data/repositories/api_catalog_repository.dart';
import 'data/repositories/api_dose_repository.dart';
import 'data/repositories/api_hydration_repository.dart';
import 'data/repositories/api_routine_repository.dart';
import 'data/repositories/api_symptom_repository.dart';
import 'data/repositories/api_system_repository.dart';
import 'data/repositories/fake_auth_repository.dart';
import 'data/repositories/fake_catalog_repository.dart';
import 'data/repositories/fake_repositories.dart';
import 'data/repositories/settings_repositories.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/catalog_repository.dart';
import 'domain/repositories/dose_repository.dart';
import 'domain/repositories/hydration_repository.dart';
import 'domain/repositories/reminder_scheduler.dart';
import 'domain/repositories/routine_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/repositories/symptom_repository.dart';
import 'domain/repositories/system_repository.dart';

/// Raiz de composição: o único lugar que sabe qual implementação de cada
/// repositório o app usa.
class AppDependencies {
  const AppDependencies({
    required this.system,
    required this.auth,
    required this.routine,
    required this.doses,
    required this.catalog,
    required this.symptoms,
    required this.hydration,
    required this.settings,
    required this.reminders,
  });

  /// API Django (`--dart-define=USE_API=true`).
  factory AppDependencies.create({DosisApi? api}) {
    final dosisApi = api ?? DosisApi.secure();
    return AppDependencies(
      system: ApiSystemRepository(dosisApi.system),
      auth: ApiAuthRepository(dosisApi.auth),
      routine: ApiRoutineRepository(dosisApi.routine),
      doses: ApiDoseRepository(dosisApi.doses),
      catalog: ApiCatalogRepository(dosisApi.catalog),
      symptoms: ApiSymptomRepository(dosisApi.symptoms),
      hydration: ApiHydrationRepository(dosisApi.hydration),
      settings: SecureSettingsRepository(),
      reminders: _platformScheduler(),
    );
  }

  /// Dados em memória: o app roda sem backend.
  factory AppDependencies.fake() {
    final routine = FakeRoutineRepository();
    return AppDependencies(
      system: FakeSystemRepository(),
      auth: FakeAuthRepository(),
      routine: routine,
      doses: FakeDoseRepository(routine),
      catalog: FakeCatalogRepository(),
      symptoms: FakeSymptomRepository(seeded: true),
      hydration: FakeHydrationRepository(),
      // Preferências e lembretes são do aparelho, não do backend: valem também no modo fake.
      settings: SecureSettingsRepository(),
      reminders: _platformScheduler(),
    );
  }

  final SystemRepository system;
  final AuthRepository auth;
  final RoutineRepository routine;
  final DoseRepository doses;
  final CatalogRepository catalog;
  final SymptomRepository symptoms;
  final HydrationRepository hydration;
  final SettingsRepository settings;
  final ReminderScheduler reminders;

  /// Notificações agendadas só existem no celular; no computador e na web nada é agendado.
  static ReminderScheduler _platformScheduler() {
    final mobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    return mobile ? LocalReminderScheduler() : NoopReminderScheduler();
  }
}