// lib/data/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/boleto_model.dart';

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // CORREÇÃO: Adicionado 'const'
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // CORREÇÃO: Adicionado 'const'
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // CORREÇÃO: Adicionado 'const'
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    tz.initializeTimeZones();

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      debugPrint('notification payload: $payload');
    }
  }

  Future<void> scheduleBoletoNotification(Boleto boleto) async {
    // CORREÇÃO: Removida a verificação desnecessária de nulo, pois dueDate não pode ser nulo.
    final DateTime dueDate = boleto.dueDate;
    // CORREÇÃO: Adicionado 'const'
    const String title = 'Lembrete de Boleto';
    
    // CORREÇÃO: Removida variável 'body' não utilizada.

    // Schedule 3 days before
    await _scheduleNotification(
      id: boleto.id.hashCode + 1,
      title: title,
      body: 'Lembrete: O boleto "${boleto.description}" vence em 3 dias!',
      // CORREÇÃO: Adicionado 'const'
      scheduledDate: dueDate.subtract(const Duration(days: 3)),
      payload: boleto.id,
    );

    // Schedule 1 day before
    await _scheduleNotification(
      id: boleto.id.hashCode + 2,
      title: title,
      body: 'Atenção: O boleto "${boleto.description}" vence amanhã!',
      // CORREÇÃO: Adicionado 'const'
      scheduledDate: dueDate.subtract(const Duration(days: 1)),
      payload: boleto.id,
    );

    // Schedule on due date
    await _scheduleNotification(
      id: boleto.id.hashCode + 3,
      title: title,
      body: 'Hoje é o dia! O boleto "${boleto.description}" vence hoje.',
      scheduledDate: dueDate,
      payload: boleto.id,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) {
      // CORREÇÃO: Substituído 'print' por 'debugPrint'.
      debugPrint('Skipping notification for $title as scheduled date is in the past.');
      return;
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      // CORREÇÃO: Adicionado 'const'
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'boleto_channel_id',
          'Lembretes de Boletos',
          channelDescription: 'Notificações para lembrar sobre o vencimento de boletos',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: payload,
    );
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}