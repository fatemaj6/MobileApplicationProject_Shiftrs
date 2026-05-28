import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FcmService {
  FcmService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ─── Init: call after login ───────────────────────────────────────────────

  static Future<void> init(String userId) async {
    if (kIsWeb) return;

    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _fcm.getToken();
    if (token != null) await _saveToken(userId, token);

    _fcm.onTokenRefresh.listen((newToken) => _saveToken(userId, newToken));
  }

  static Future<void> _saveToken(String userId, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  // ─── Notify patient + family about an appointment ─────────────────────────

  static Future<void> notifyAppointment({
    required String patientId,
    required String appointmentTitle,
    required String doctorName,
    required DateTime appointmentDateTime,
    required String appointmentId,
  }) async {
    if (kIsWeb) return;

    // 1. Collect all user IDs to notify
    final userIds = <String>{patientId};

    // 2. Find family members linked to this patient
    final familySnap = await FirebaseFirestore.instance
        .collection('users')
        .where('linkedPatientId', isEqualTo: patientId)
        .where('role', isEqualTo: 'family')
        .get();

    for (final doc in familySnap.docs) {
      userIds.add(doc.id);
    }

    // 3. Collect FCM tokens
    final tokens = <String>[];
    for (final uid in userIds) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final token = doc.data()?['fcmToken'] as String?;
      if (token != null) tokens.add(token);
    }

    if (tokens.isEmpty) return;

    // 4. Format time
    final timeStr =
        '${appointmentDateTime.hour.toString().padLeft(2, '0')}:'
        '${appointmentDateTime.minute.toString().padLeft(2, '0')}';

    // 5. Send via FCM HTTP v1 API to each token
    for (final token in tokens) {
      await _sendFcmMessage(
        token: token,
        title: '🏥 Upcoming Appointment',
        body: '$appointmentTitle with $doctorName at $timeStr',
        data: {'appointmentId': appointmentId, 'type': 'appointment_reminder'},
      );
    }
  }

  static Future<void> _sendFcmMessage({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    // Get FCM access token from Firebase Auth
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=YOUR_SERVER_KEY', // ← replace with your FCM server key
      },
      body: jsonEncode({
        'to': token,
        'notification': {'title': title, 'body': body},
        'data': data,
        'priority': 'high',
      }),
    );
  }
}