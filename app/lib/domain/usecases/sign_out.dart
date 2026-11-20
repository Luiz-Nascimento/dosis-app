import '../repositories/auth_repository.dart';
import '../repositories/reminder_scheduler.dart';
import '../repositories/settings_repository.dart';

/// "Sair da conta": encerra a sessão e apaga do aparelho o que é da pessoa.
///
/// Os lembretes agendados trazem nomes dos itens da rotina e as preferências
/// guardam a meta de água calculada pelo peso. Se ficassem no aparelho, a
/// próxima conta a entrar (ou ninguém, com o app deslogado) continuaria
/// recebendo as notificações da conta anterior.
class SignOut {
  const SignOut(this._auth, this._settings, this._reminders);

  final AuthRepository _auth;
  final SettingsRepository _settings;
  final ReminderScheduler _reminders;

  Future<void> call() async {
    // A sessão é encerrada primeiro: mesmo que a limpeza falhe, a pessoa sai da conta.
    await _auth.signOut();

    // Cada limpeza é independente: uma falha (ex.: plugin de notificações
    // indisponível) não pode impedir a outra.
    try {
      await _reminders.replaceAll(const []);
    } catch (_) {}
    try {
      await _settings.clear();
    } catch (_) {}
  }
}
