import '../../data/models/settings.dart';

/// Agenda as notificações locais do aparelho. O domínio só conhece esta
/// interface: o plugin de notificações fica na camada de dados.
abstract interface class ReminderScheduler {
  /// Pede a permissão de notificações ao sistema. `false` se o usuário negar.
  Future<bool> requestPermission();

  /// Cancela tudo o que estava agendado e agenda [reminders], repetindo todo dia.
  Future<void> replaceAll(List<Reminder> reminders);
}
