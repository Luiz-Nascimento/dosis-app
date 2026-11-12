import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/repositories/reminder_scheduler.dart';
import '../models/settings.dart';

/// Notificações locais de verdade (Android e iOS), com `flutter_local_notifications`.
///
/// Cada lembrete se repete todo dia no mesmo horário. O agendamento é
/// "inexato": o Android pode atrasar alguns minutos para economizar bateria,
/// e em troca o app não precisa da permissão especial de alarme exato.
class LocalReminderScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    } catch (_) {
      // Fuso desconhecido pela base de dados: usa o de Brasília.
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // A permissão é pedida em [requestPermission], não ao abrir o app.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? true;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    return true;
  }

  @override
  Future<void> replaceAll(List<Reminder> reminders) async {
    await _init();
    await _plugin.cancelAll();
    for (final reminder in reminders) {
      final water = reminder.kind == ReminderKind.water;
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: _next(reminder.hour, reminder.minute),
        notificationDetails: NotificationDetails(
          // Um canal por tipo: o usuário pode silenciar só a água nas configurações do Android.
          android: AndroidNotificationDetails(
            water ? 'dosis_water' : 'dosis_supplements',
            water ? 'Lembretes de água' : 'Lembretes de suplementos',
            channelDescription: water
                ? 'Lembra de beber água ao longo do dia.'
                : 'Lembra dos horários dos itens da sua rotina.',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // Repete todo dia no mesmo horário.
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Próxima vez que o relógio marcar [hour]:[minute] (hoje ou amanhã).
  tz.TZDateTime _next(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    final today = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }
}

/// Onde não há notificações agendadas (computador, web) e nos testes:
/// só guarda o que seria agendado.
class NoopReminderScheduler implements ReminderScheduler {
  NoopReminderScheduler({this.permissionGranted = true});

  final bool permissionGranted;

  /// Último conjunto "agendado".
  List<Reminder> scheduled = const [];

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> replaceAll(List<Reminder> reminders) async => scheduled = reminders;
}
