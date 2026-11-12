import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_dependencies.dart';
import '../data/models/tracking.dart';
import '../domain/usecases/build_risk_panel.dart';
import '../domain/usecases/build_weekly_symptom_report.dart';
import '../domain/usecases/calculate_hydration.dart';
import '../domain/usecases/check_dose_safety.dart';
import '../domain/usecases/get_dose_history.dart';
import '../domain/usecases/get_supplement_history.dart';
import '../domain/usecases/get_today_stack.dart';
import '../domain/usecases/register_dose.dart';
import '../domain/usecases/register_symptoms.dart';
import '../data/models/auth.dart';
import '../data/models/settings.dart';
import '../domain/usecases/hydration_goals.dart';
import '../domain/usecases/update_settings.dart';
import '../domain/repositories/auth_repository.dart';

/// Preenchido no `main` com a implementação escolhida (fake ou API).
final dependenciesProvider = Provider<AppDependencies>(
  (ref) => throw UnimplementedError('dependenciesProvider precisa de override no ProviderScope'),
);

final getTodayStackProvider =
    Provider<GetTodayStack>((ref) => GetTodayStack(ref.watch(dependenciesProvider).routine));
final registerDoseProvider =
    Provider<RegisterDose>((ref) => RegisterDose(ref.watch(dependenciesProvider).doses));
final registerSymptomsProvider =
    Provider<RegisterSymptoms>((ref) => RegisterSymptoms(ref.watch(dependenciesProvider).symptoms));
final getDoseHistoryProvider =
    Provider<GetDoseHistory>((ref) => GetDoseHistory(ref.watch(dependenciesProvider).doses));
final calculateHydrationProvider =
    Provider<CalculateHydration>((ref) => const CalculateHydration());
final checkDoseSafetyProvider = Provider<CheckDoseSafety>((ref) {
  final deps = ref.watch(dependenciesProvider);
  return CheckDoseSafety(deps.catalog, deps.doses);
});

final getSupplementHistoryProvider = Provider<GetSupplementHistory>((ref) {
  final deps = ref.watch(dependenciesProvider);
  return GetSupplementHistory(deps.doses, deps.catalog);
});

final todayStackProvider = FutureProvider<List<RoutineItem>>((ref) => ref.watch(getTodayStackProvider)());
final doseHistoryProvider = FutureProvider<List<DoseLog>>((ref) => ref.watch(getDoseHistoryProvider)());

/// Histórico por suplemento dos últimos N dias (o parâmetro é o número de dias).
final supplementHistoryProvider = FutureProvider.family<List<SupplementHistory>, int>((ref, days) {
  // Depende do histórico geral: registrar uma dose nova recalcula os gráficos.
  ref.watch(doseHistoryProvider);
  return ref.watch(getSupplementHistoryProvider)(days: days);
});

/// Aba selecionada do menu de baixo (0 início, 1 rotina, 2 hidratação, 3 registros).
class TabIndex extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final tabIndexProvider = NotifierProvider<TabIndex, int>(TabIndex.new);


final authRepositoryProvider =
    Provider<AuthRepository>((ref) => ref.watch(dependenciesProvider).auth);

/// `true` quando há sessão aberta. Decide entre a tela de boas-vindas e o app.
class Session extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(authRepositoryProvider).isSignedIn();

  void signedIn() => state = const AsyncData(true);

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    ref.read(tabIndexProvider.notifier).select(0);
    state = const AsyncData(false);
  }
}

final sessionProvider = AsyncNotifierProvider<Session, bool>(Session.new);

final accountProvider = FutureProvider<Account>((ref) {
  ref.watch(sessionProvider);
  return ref.watch(authRepositoryProvider).account();
});

// ---- Meta de hidratação e lembretes ----

final getHydrationProgressProvider = Provider<GetHydrationProgress>((ref) {
  final deps = ref.watch(dependenciesProvider);
  return GetHydrationProgress(deps.hydration, deps.settings);
});
final logWaterProvider = Provider<LogWater>((ref) => LogWater(ref.watch(dependenciesProvider).hydration));
final removeWaterLogProvider =
    Provider<RemoveWaterLog>((ref) => RemoveWaterLog(ref.watch(dependenciesProvider).hydration));
final updateSettingsProvider = Provider<UpdateSettings>((ref) {
  final deps = ref.watch(dependenciesProvider);
  return UpdateSettings(deps.settings, deps.routine, deps.reminders);
});

/// Preferências do aparelho. `save` valida, reagenda os lembretes e atualiza quem estiver ouvindo.
class Settings extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() => ref.read(dependenciesProvider).settings.load();

  Future<SettingsUpdate> save(UserSettings settings) async {
    final update = await ref.read(updateSettingsProvider)(settings);
    state = AsyncData(update.settings);
    return update;
  }
}

final settingsProvider = AsyncNotifierProvider<Settings, UserSettings>(Settings.new);

/// Progresso de hoje e dos últimos 7 dias. Recalcula quando a meta muda.
final hydrationProgressProvider = FutureProvider<HydrationProgress>((ref) {
  ref.watch(settingsProvider);
  return ref.watch(getHydrationProgressProvider)();
});

// ---- Painel de risco e relatório semanal de sintomas ----

final buildRiskPanelProvider = Provider<BuildRiskPanel>((ref) {
  final deps = ref.watch(dependenciesProvider);
  return BuildRiskPanel(deps.doses, deps.catalog, deps.symptoms);
});
final buildWeeklySymptomReportProvider = Provider<BuildWeeklySymptomReport>(
  (ref) => BuildWeeklySymptomReport(ref.watch(dependenciesProvider).symptoms),
);

/// Sintomas registrados, mais recentes primeiro. Invalide depois de gravar um
/// registro novo: o painel, o relatório e a aba Registros dependem dele.
final symptomHistoryProvider = FutureProvider<List<SymptomLog>>(
  (ref) => ref.watch(dependenciesProvider).symptoms.list(limit: 500),
);

/// Painel dos últimos 7 dias. Recalcula quando entra uma dose ou um sintoma novo.
final riskPanelProvider = FutureProvider<RiskPanel>((ref) {
  ref.watch(doseHistoryProvider);
  ref.watch(symptomHistoryProvider);
  return ref.watch(buildRiskPanelProvider)();
});

/// Relatório de uma semana (o parâmetro é o deslocamento: 0 = atual, -1 = anterior).
final symptomReportProvider = FutureProvider.family<WeeklySymptomReport, int>((ref, weekOffset) {
  ref.watch(symptomHistoryProvider);
  return ref.watch(buildWeeklySymptomReportProvider)(weekOffset: weekOffset);
});
