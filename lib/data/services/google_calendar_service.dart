import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;

import 'google_signin_web.dart';

class GoogleCalendarService {
  static const _calendarScope =
      'https://www.googleapis.com/auth/calendar';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [_calendarScope],
  );

  // ─── Get valid auth headers (ID token on web ≠ access token) ──────────

  static Future<Map<String, String>?> _getAuthHeaders(
      GoogleSignInAccount account) async {
    if (kIsWeb) {
      // On web, GIS separates authentication (renderButton → ID token)
      // from authorization (requestScopes → OAuth2 access token).
      // The Calendar API needs the OAuth2 access token, so we must
      // call requestScopes() to get one before calling authHeaders.
      final hasScope =
          await _googleSignIn.canAccessScopes([_calendarScope]);

      if (!hasScope) {
        final granted =
            await _googleSignIn.requestScopes([_calendarScope]);
        if (!granted) {
          debugPrint('Calendar scope not granted by user.');
          return null;
        }
      }
    }

    return account.authHeaders;
  }

  // ─── Internal: unified sign-in for mobile + web ───────────────────────

  static Future<GoogleSignInAccount?> _ensureSignedIn(
      BuildContext context) async {
    final silent = await _googleSignIn.signInSilently();
    if (silent != null) return silent;

    if (kIsWeb) {
      return _showWebSignInDialog(context);
    }

    return _googleSignIn.signIn();
  }

  static Future<GoogleSignInAccount?> _showWebSignInDialog(
      BuildContext context) async {
    final completer = Completer<GoogleSignInAccount?>();

    final sub = _googleSignIn.onCurrentUserChanged.listen((account) {
      if (account != null && !completer.isCompleted) {
        completer.complete(account);
      }
    });

    if (!context.mounted) {
      await sub.cancel();
      return null;
    }

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Connect Google Calendar'),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sign in with Google to sync this appointment to your calendar.',
                  style:
                      TextStyle(fontSize: 14, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 20),
                buildWebSignInButton(_googleSignIn),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (!completer.isCompleted) completer.complete(null);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ).then((_) {
        if (!completer.isCompleted) completer.complete(null);
      }),
    );

    final account = await completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => null,
    );

    await sub.cancel();

    if (context.mounted) {
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) navigator.pop();
    }

    return account;
  }

  // ─── Create ───────────────────────────────────────────────────────────

  static Future<String?> syncAppointment({
    required BuildContext context,
    required String title,
    required String description,
    required DateTime startTime,
    Duration duration = const Duration(hours: 1),
  }) async {
    try {
      final account = await _ensureSignedIn(context);
      if (account == null) return null;

      // ← get OAuth2 access token (not just ID token)
      final authHeaders = await _getAuthHeaders(account);
      if (authHeaders == null) return null;

      final client = _AuthenticatedClient(http.Client(), authHeaders);
      final calendarApi = gcal.CalendarApi(client);

      final event = gcal.Event()
        ..summary = title
        ..description = description
        ..start = gcal.EventDateTime(
          dateTime: startTime.toUtc(),
          timeZone: 'Asia/Kuala_Lumpur',
        )
        ..end = gcal.EventDateTime(
          dateTime: startTime.add(duration).toUtc(),
          timeZone: 'Asia/Kuala_Lumpur',
        )
        ..reminders = gcal.EventReminders(
          useDefault: false,
          overrides: [
            gcal.EventReminder(method: 'popup', minutes: 30),
            gcal.EventReminder(method: 'email', minutes: 60),
          ],
        );

      final createdEvent =
          await calendarApi.events.insert(event, 'primary');
      client.close();
      return createdEvent.id;
    } catch (e) {
      debugPrint('Google Calendar sync failed: $e');
      return null;
    }
  }

  // ─── Update ───────────────────────────────────────────────────────────

  static Future<String?> updateEvent({
    required String googleEventId,
    required String title,
    required String description,
    required DateTime startTime,
    Duration duration = const Duration(hours: 1),
  }) async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return null;

      // ← get OAuth2 access token
      final authHeaders = await _getAuthHeaders(account);
      if (authHeaders == null) return null;

      final client = _AuthenticatedClient(http.Client(), authHeaders);
      final calendarApi = gcal.CalendarApi(client);

      final event = gcal.Event()
        ..summary = title
        ..description = description
        ..start = gcal.EventDateTime(
          dateTime: startTime.toUtc(),
          timeZone: 'Asia/Kuala_Lumpur',
        )
        ..end = gcal.EventDateTime(
          dateTime: startTime.add(duration).toUtc(),
          timeZone: 'Asia/Kuala_Lumpur',
        )
        ..reminders = gcal.EventReminders(
          useDefault: false,
          overrides: [
            gcal.EventReminder(method: 'popup', minutes: 30),
            gcal.EventReminder(method: 'email', minutes: 60),
          ],
        );

      try {
        await calendarApi.events.update(event, 'primary', googleEventId);
        client.close();
        return googleEventId;
      } catch (e) {
        if (e.toString().contains('404') ||
            e.toString().contains('notFound')) {
          debugPrint('Event not found. Re-creating.');
          final createdEvent =
              await calendarApi.events.insert(event, 'primary');
          client.close();
          return createdEvent.id;
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Google Calendar update failed: $e');
      return null;
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────

  static Future<bool> deleteEvent(String googleEventId) async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return false;

      // ← get OAuth2 access token
      final authHeaders = await _getAuthHeaders(account);
      if (authHeaders == null) return false;

      final client = _AuthenticatedClient(http.Client(), authHeaders);
      final calendarApi = gcal.CalendarApi(client);

      await calendarApi.events.delete('primary', googleEventId);
      client.close();
      return true;
    } catch (e) {
      debugPrint('Google Calendar delete failed: $e');
      if (e.toString().contains('404') ||
          e.toString().contains('notFound')) {
        return true;
      }
      return false;
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