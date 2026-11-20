import '../../data/models/settings.dart';

/// Preferências do usuário guardadas no aparelho (meta de água e lembretes).
abstract interface class SettingsRepository {
  /// Devolve os valores padrão quando nada foi salvo ainda.
  Future<UserSettings> load();

  Future<void> save(UserSettings settings);

  /// Apaga as preferências salvas (ao sair da conta). Depois disso, [load] devolve o padrão.
  Future<void> clear();
}
