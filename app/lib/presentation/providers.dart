import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_dependencies.dart';
import '../data/models/tracking.dart';
import '../domain/usecases/calculate_hydration.dart';
import '../domain/usecases/check_dose_safety.dart';
import '../domain/usecases/get_dose_history.dart';
import '../domain/usecases/get_today_stack.dart';
import '../domain/usecases/register_dose.dart';
import '../data/models/auth.dart';
import '../domain/repositories/auth_repository.dart';

/// Preenchido no `main` com a implementação escolhida (fake ou API).
final dependenciesProvider = Provider<AppDependencies>(
  (ref) => throw UnimplementedError('dependenciesProvider precisa de override no ProviderScope'),
);

final getTodayStackProvider =
    Provider<GetTodayStack>((ref) => GetTodayStack(ref.watch(dependenciesProvider).routine));
final registerDoseProvider =
    Provider<RegisterDose>((ref) => RegisterDose(ref.watch(dependenciesProvider).doses));
final getDoseHistoryProvider =
    Provider<GetDoseHistory>((ref) => GetDoseHistory(ref.watch(dependenciesProvider).doses));
final calculateHydrationProvider =
    Provider<CalculateHydration>((ref) => const CalculateHydration());
final checkDoseSafetyProvider = Provider<CheckDoseSafety>((ref) {
  final deps = ref.watch(dependenciesProvider);
  return CheckDoseSafety(deps.catalog, deps.doses);
});

final todayStackProvider = FutureProvider<List<RoutineItem>>((ref) => ref.watch(getTodayStackProvider)());
final doseHistoryProvider = FutureProvider<List<DoseLog>>((ref) => ref.watch(getDoseHistoryProvider)());

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