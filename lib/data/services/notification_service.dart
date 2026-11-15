import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Serviço stateless de Notificações Locais para alertas de empréstimos e lembretes.
/// Slide 25 da Aula 24 (Arquitetura Flutter).
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _initialized = false;

  NotificationService({FlutterLocalNotificationsPlugin? notificationsPlugin})
      : _notificationsPlugin = notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(initSettings);
      _initialized = true;
    } catch (_) {}
  }

  /// Agenda ou emite lembrete de devolução de livro emprestado
  Future<void> scheduleLoanReturnReminder({
    required int id,
    required String bookTitle,
    required String borrowerName,
    required DateTime expectedReturnDate,
  }) async {
    await init();
    try {
      const androidDetails = AndroidNotificationDetails(
        'loan_reminders_channel',
        'Lembretes de Empréstimos',
        channelDescription: 'Alertas de devolução de livros emprestados para amigos',
        importance: Importance.high,
        priority: Priority.high,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id,
        'Devolução de Livro: $bookTitle',
        'Data prevista para $borrowerName devolver "$bookTitle".',
        notificationDetails,
      );
    } catch (_) {}
  }

  /// Cancela notificação agendada quando o livro for devolvido
  Future<void> cancelNotification(int id) async {
    await init();
    try {
      await _notificationsPlugin.cancel(id);
    } catch (_) {}
  }
}
