import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Inicializar timezone
    tz.initializeTimeZones();

    // Configurações Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configurações iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Solicitar permissões
    await _requestPermissions();

    // Configurar FCM
    await _setupFCM();
  }

  Future<void> _requestPermissions() async {
    // Solicitar permissões Firebase
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android 13+ requer permissão explícita
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _setupFCM() async {
    String? token = await _firebaseMessaging.getToken();
    if (kDebugMode) print('FCM Token: $token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(
        title: message.notification?.title ?? 'Nova notificação',
        body: message.notification?.body ?? '',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) print('Notificação aberta: ${message.messageId}');
    });
  }

  void _onNotificationTap(NotificationResponse response) {
    if (kDebugMode) print('Notificação tocada: ${response.payload}');
  }

  // Mostrar notificação simples
  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Notificações Gerais',
      channelDescription: 'Canal para notificações gerais do app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Alerta de orçamento excedido
  Future<void> showBudgetAlert({
    required String category,
    required double spent,
    required double budget,
  }) async {
    final percent = (spent / budget * 100).toStringAsFixed(0);
    await _showNotification(
      title: '⚠️ Orçamento de $category ultrapassado!',
      body:
          'Você gastou ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(spent)} de ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(budget)} ($percent%)',
      payload: 'budget_alert_$category',
    );
  }

  // Alerta quando está perto do limite
  Future<void> showBudgetWarning({
    required String category,
    required double spent,
    required double budget,
  }) async {
    final percent = (spent / budget * 100).toStringAsFixed(0);
    await _showNotification(
      title: '⚡ Atenção ao orçamento de $category',
      body:
          'Você já gastou $percent% do seu orçamento (${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(spent)}/${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(budget)})',
      payload: 'budget_warning_$category',
    );
  }

  // Resumo semanal
  Future<void> showWeeklySummary({
    required double totalExpenses,
    required double totalIncome,
    required int transactionCount,
  }) async {
    final balance = totalIncome - totalExpenses;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    await _showNotification(
      title: '📊 Resumo Semanal',
      body:
          'Receitas: ${formatter.format(totalIncome)} | Gastos: ${formatter.format(totalExpenses)} | Saldo: ${formatter.format(balance)} | $transactionCount transações',
      payload: 'weekly_summary',
    );
  }

  // Resumo mensal
  Future<void> showMonthlySummary({
    required double totalExpenses,
    required double totalIncome,
    required int transactionCount,
    required String topCategory,
    required double topCategoryAmount,
  }) async {
    final balance = totalIncome - totalExpenses;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    await _showNotification(
      title: '🎯 Fechamento do Mês',
      body:
          'Saldo: ${formatter.format(balance)} | $transactionCount transações | Maior gasto: $topCategory (${formatter.format(topCategoryAmount)})',
      payload: 'monthly_summary',
    );
  }

  // Lembrete de conta recorrente
  Future<void> showRecurringReminder({
    required String description,
    required double amount,
    required DateTime dueDate,
  }) async {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormatter = DateFormat('dd/MM', 'pt_BR');

    await _showNotification(
      title: '🔔 Lembrete de Conta',
      body:
          '$description - ${formatter.format(amount)} vence em ${dateFormatter.format(dueDate)}',
      payload: 'recurring_reminder',
    );
  }

  // Insight automático
  Future<void> showInsight({
    required String title,
    required String message,
  }) async {
    await _showNotification(
      title: '💡 $title',
      body: message,
      payload: 'insight',
    );
  }

  // Agendar notificação para uma data específica
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'scheduled_channel',
      'Notificações Agendadas',
      channelDescription: 'Canal para notificações agendadas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _convertToTZDateTime(scheduledDate),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    final location = tz.getLocation('America/Sao_Paulo');
    return tz.TZDateTime.from(dateTime, location);
  }

  // Cancelar notificação agendada
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancelar todas as notificações
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
