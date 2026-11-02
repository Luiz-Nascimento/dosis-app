import 'data/dosis_api.dart';
import 'data/repositories/api_dose_repository.dart';
import 'data/repositories/api_routine_repository.dart';
import 'data/repositories/api_system_repository.dart';
import 'data/repositories/fake_repositories.dart';
import 'domain/repositories/dose_repository.dart';
import 'domain/repositories/routine_repository.dart';
import 'domain/repositories/system_repository.dart';

/// Raiz de composição: o único lugar que sabe qual implementação de cada
/// repositório o app usa.
class AppDependencies {
  const AppDependencies({required this.system, required this.routine, required this.doses});

  /// API Django (`--dart-define=USE_API=true`).
  factory AppDependencies.create({DosisApi? api}) {
    final dosisApi = api ?? DosisApi.secure();
    return AppDependencies(
      system: ApiSystemRepository(dosisApi.system),
      routine: ApiRoutineRepository(dosisApi.routine),
      doses: ApiDoseRepository(dosisApi.doses),
    );
  }

  /// Dados em memória: o app roda sem backend.
  factory AppDependencies.fake() {
    final routine = FakeRoutineRepository();
    return AppDependencies(
      system: FakeSystemRepository(),
      routine: routine,
      doses: FakeDoseRepository(routine),
    );
  }

  final SystemRepository system;
  final RoutineRepository routine;
  final DoseRepository doses;
}