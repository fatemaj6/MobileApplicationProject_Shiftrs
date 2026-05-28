import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ─── Init ────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (kIsWeb) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );

    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  // ─── Medication: immediate ───────────────────────────────────────────────

  static Future<void> showMedicationReminderNow({
    required int id,
    required String medicationName,
  }) async {
    if (kIsWeb) return;

    await _plugin.show(
      id: id,
      title: 'Medication Reminder',
      body: '$medicationName is due soon.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Reminders before medication time',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> showMissedMedicationNow({
    required int id,
    required String medicationName,
  }) async {
    if (kIsWeb) return;

    await _plugin.show(
      id: id,
      title: 'Missed Medication Alert',
      body: '$medicationName may have been missed.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'missed_medication_alerts',
          'Missed Medication Alerts',
          channelDescription: 'Alerts when medication may have been missed',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ─── Appointments: scheduled (SMAP-28) ───────────────────────────────────

  static Future<void> scheduleAppointmentReminder({
    required int id,
    required String title,
    required String doctorName,
    required DateTime appointmentTime,
    int minutesBefore = 30,
  }) async {
    if (kIsWeb) return;

    final reminderTime =
        appointmentTime.subtract(Duration(minutes: minutesBefore));

    if (reminderTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: id,
      title: '🏥 Upcoming Appointment',
      body: '$title with $doctorName in $minutesBefore minutes',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'appointment_reminders',
          'Appointment Reminders',
          channelDescription: 'Reminders before scheduled appointments',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelAppointmentReminder(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id: id);
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}