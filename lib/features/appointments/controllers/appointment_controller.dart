import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/fcm_service.dart'; // ← ADD
import '../../../data/services/google_calendar_service.dart';


class AppointmentController extends ChangeNotifier {
  final AppointmentRepository _repository = AppointmentRepository();

  bool isLoading = false;
  String? errorMessage;

  String get caregiverId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ─── Stream ───────────────────────────────────────────────────────────────

  Stream<List<AppointmentModel>> streamAppointments() {
    return _repository.streamAppointmentsForCaregiver(caregiverId);
  }

  // ─── Add ──────────────────────────────────────────────────────────────────

  Future<bool> addAppointment(AppointmentModel appointment) async {
    _setLoading(true);
    try {
      final withCaregiver = appointment.copyWith(caregiverId: caregiverId);
      await _repository.addAppointment(withCaregiver);

      // SMAP-28: local reminder on caregiver's device
      await _scheduleReminder(withCaregiver);

      // FCM: push to patient + family if patientId is set
      if (withCaregiver.patientId != null) {
        await FcmService.notifyAppointment(
          patientId: withCaregiver.patientId!,
          appointmentTitle: withCaregiver.title,
          doctorName: withCaregiver.doctorName,
          appointmentDateTime: withCaregiver.appointmentDateTime,
          appointmentId: withCaregiver.id,
        );
      }

      return true;
    } catch (e) {
      errorMessage = 'Failed to add appointment: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<bool> updateAppointment(AppointmentModel appointment) async {
    _setLoading(true);
    try {
      final oldAppointment = await _repository.getAppointment(appointment.id);
      AppointmentModel appointmentToSave = appointment;

      if (oldAppointment != null) {
        final detailsChanged = oldAppointment.title != appointment.title ||
            oldAppointment.notes != appointment.notes ||
            oldAppointment.appointmentDateTime != appointment.appointmentDateTime ||
            oldAppointment.doctorName != appointment.doctorName ||
            oldAppointment.specialty != appointment.specialty ||
            oldAppointment.clinicName != appointment.clinicName ||
            oldAppointment.appointmentType != appointment.appointmentType;

        if (detailsChanged && oldAppointment.googleEventId != null && oldAppointment.googleEventId!.isNotEmpty) {
          final description = appointment.notes.isNotEmpty
              ? appointment.notes
              : '${appointment.specialty} with ${appointment.doctorName}';

          final eventId = await GoogleCalendarService.updateEvent(
            googleEventId: oldAppointment.googleEventId!,
            title: appointment.title,
            description: description,
            startTime: appointment.appointmentDateTime,
          );

          if (eventId != null) {
            appointmentToSave = appointment.copyWith(
              googleEventId: eventId,
              googleEventSyncState: 'synced',
            );
          } else {
            // Failed due to offline or token expiry, mark for update retry
            appointmentToSave = appointment.copyWith(
              googleEventSyncState: 'pending_update',
            );
          }
        }
      }

      await _repository.updateAppointment(appointmentToSave);

      // SMAP-28: reschedule local reminder
      await NotificationService.cancelAppointmentReminder(
        appointmentToSave.id.hashCode,
      );
      await _scheduleReminder(appointmentToSave);

      // FCM: notify patient + family of updated time
      if (appointmentToSave.patientId != null) {
        await FcmService.notifyAppointment(
          patientId: appointmentToSave.patientId!,
          appointmentTitle: appointmentToSave.title,
          doctorName: appointmentToSave.doctorName,
          appointmentDateTime: appointmentToSave.appointmentDateTime,
          appointmentId: appointmentToSave.id,
        );
      }

      return true;
    } catch (e) {
      errorMessage = 'Failed to update appointment: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<bool> deleteAppointment(String appointmentId) async {
    try {
      final appointment = await _repository.getAppointment(appointmentId);
      
      if (appointment != null &&
          appointment.googleEventId != null &&
          appointment.googleEventId!.isNotEmpty) {
        final success = await GoogleCalendarService.deleteEvent(appointment.googleEventId!);
        
        if (success) {
          await _repository.updateAppointment(appointment.copyWith(
            googleEventSyncState: 'synced',
          ));
        } else {
          // Failed (offline), mark for delete retry
          await _repository.updateAppointment(appointment.copyWith(
            googleEventSyncState: 'pending_delete',
          ));
        }
      }

      await _repository.deleteAppointment(appointmentId);

      await NotificationService.cancelAppointmentReminder(
        appointmentId.hashCode,
      );

      return true;
    } catch (e) {
      errorMessage = 'Failed to delete appointment: $e';
      notifyListeners();
      return false;
    }
  }

  // ─── Offline/Background Sync Reconciler ────────────────────────────────────

  bool isLoadingPendingSyncs = false;

  Future<void> processPendingCalendarSyncs() async {
    if (caregiverId.isEmpty || isLoadingPendingSyncs) return;
    isLoadingPendingSyncs = true;

    try {
      final appointments = await _repository.getAppointmentsIncludingDeleted(caregiverId);
      for (final appt in appointments) {
        if (appt.googleEventId == null || appt.googleEventId!.isEmpty) continue;

        if (appt.googleEventSyncState == 'pending_update') {
          final description = appt.notes.isNotEmpty
              ? appt.notes
              : '${appt.specialty} with ${appt.doctorName}';

          final eventId = await GoogleCalendarService.updateEvent(
            googleEventId: appt.googleEventId!,
            title: appt.title,
            description: description,
            startTime: appt.appointmentDateTime,
          );

          if (eventId != null) {
            await _repository.updateAppointment(
              appt.copyWith(
                googleEventId: eventId,
                googleEventSyncState: 'synced',
              ),
            );
          }
        } else if (appt.googleEventSyncState == 'pending_delete') {
          final success = await GoogleCalendarService.deleteEvent(appt.googleEventId!);
          if (success) {
            await _repository.updateAppointment(
              appt.copyWith(googleEventSyncState: 'synced'),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing pending calendar syncs: $e');
    } finally {
      isLoadingPendingSyncs = false;
    }
  }

  // ─── SMAP-28 helper ───────────────────────────────────────────────────────

  Future<void> _scheduleReminder(AppointmentModel appointment) async {
    if (appointment.isPast || appointment.status == 'cancelled') return;

    await NotificationService.scheduleAppointmentReminder(
      id: appointment.id.hashCode,
      title: appointment.title,
      doctorName: appointment.doctorName,
      appointmentTime: appointment.appointmentDateTime,
      minutesBefore: 30,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}