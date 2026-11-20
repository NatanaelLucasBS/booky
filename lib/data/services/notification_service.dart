import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Serviço de notificações locais (empréstimos e lembrete diário)
class NotificationService {
  static const int dailyReadingReminderId = 999001;

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _initialized = false;

  NotificationService({FlutterLocalNotificationsPlugin? notificationsPlugin})
      : _notificationsPlugin =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await initialize();
  }

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {}

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(initSettings);
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      _initialized = true;
    } catch (_) {}
  }

  /// Agenda lembrete de devolução de livro emprestado para a data prevista.
  Future<void> scheduleLoanReturnReminder({
    required int id,
    required String bookTitle,
    required String borrowerName,
    required DateTime expectedReturnDate,
  }) async {
    await initialize();
    try {
      const androidDetails = AndroidNotificationDetails(
        'loan_reminders_channel',
        'Lembretes de Empréstimos',
        channelDescription:
            'Alertas de devolução de livros emprestados para amigos',
        importance: Importance.high,
        priority: Priority.high,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      final targetDate = DateTime(
        expectedReturnDate.year,
        expectedReturnDate.month,
        expectedReturnDate.day,
        9,
        0,
      );
      final now = DateTime.now();

      if (targetDate.isAfter(now)) {
        final scheduledTz = tz.TZDateTime.from(targetDate, tz.local);
        await _notificationsPlugin.zonedSchedule(
          id,
          'Devolução de Livro: $bookTitle',
          'Data prevista para $borrowerName devolver "$bookTitle".',
          scheduledTz,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else {
        await _notificationsPlugin.show(
          id,
          'Devolução de Livro: $bookTitle',
          'Data prevista para $borrowerName devolver "$bookTitle".',
          notificationDetails,
        );
      }
    } catch (_) {}
  }

  /// Cancela notificação agendada quando o livro for devolvido.
  Future<void> cancelNotification(int id) async {
    await initialize();
    try {
      await _notificationsPlugin.cancel(id);
    } catch (_) {}
  }

  /// Agenda lembrete diário recorrente de leitura no horário escolhido.
  Future<void> scheduleDailyReadingReminder({
    required int hour,
    required int minute,
  }) async {
    await initialize();
    try {
      const androidDetails = AndroidNotificationDetails(
        'daily_reading_channel',
        'Lembrete Diário de Leitura',
        channelDescription:
            'Notificações diárias para manter o hábito de leitura no Booky',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour.clamp(0, 23),
        minute.clamp(0, 59),
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        dailyReadingReminderId,
        'Hora da Leitura no BOOKY',
        'Reserve alguns minutos hoje para avançar na sua leitura atual!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  /// Cancela o lembrete diário de leitura.
  Future<void> cancelDailyReadingReminder() async {
    await cancelNotification(dailyReadingReminderId);
  }
}
