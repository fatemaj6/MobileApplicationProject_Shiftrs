// google_calendar_service.dart
import 'package:flutter/foundation.dart'; // for debugPrint — FIX
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/calendar'],
  );

  static Future<String?> syncAppointment({
    required String title,
    required String description,
    required DateTime startTime,
    Duration duration = const Duration(hours: 1),
  }) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final authHeaders = await account.authHeaders;
      final client = _AuthenticatedClient(http.Client(), authHeaders);
      final calendarApi = gcal.CalendarApi(client);

      final event = gcal.Event()
        ..summary = title
        ..description = description
        ..start = gcal.EventDateTime(
          dateTime: startTime,
          timeZone: 'Asia/Kuala_Lumpur',
        )
        ..end = gcal.EventDateTime(
          dateTime: startTime.add(duration),
          timeZone: 'Asia/Kuala_Lumpur',
        )
        ..reminders = gcal.EventReminders(
          useDefault: false,
          overrides: [
            gcal.EventReminder(method: 'popup', minutes: 30),
            gcal.EventReminder(method: 'email', minutes: 60),
          ],
        );

      final createdEvent = await calendarApi.events.insert(event, 'primary');
      client.close();
      return createdEvent.id;
    } catch (e) {
      debugPrint('Google Calendar sync failed: $e');
      return null;
    }
  }

  static Future<void> deleteEvent(String googleEventId) async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return;

      final authHeaders = await account.authHeaders;
      final client = _AuthenticatedClient(http.Client(), authHeaders);
      final calendarApi = gcal.CalendarApi(client);

      await calendarApi.events.delete('primary', googleEventId);
      client.close();
    } catch (e) {
      debugPrint('Google Calendar delete failed: $e');
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}

class _AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _headers;

  _AuthenticatedClient(this._inner, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}