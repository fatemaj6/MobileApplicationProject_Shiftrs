import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: settings,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showMedicationReminderNow({
    required int id,
    required String medicationName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders before medication time',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: id,
      title: 'Medication Reminder',
      body: '$medicationName is due soon.',
      notificationDetails: details,
    );
  }

  static Future<void> showMissedMedicationNow({
    required int id,
    required String medicationName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'missed_medication_alerts',
      'Missed Medication Alerts',
      channelDescription: 'Alerts when medication may have been missed',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: id,
      title: 'Missed Medication Alert',
      body: '$medicationName may have been missed.',
      notificationDetails: details,
    );
  }
}