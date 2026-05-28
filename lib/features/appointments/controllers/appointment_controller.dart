import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/fcm_service.dart'; // ← ADD

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
      await _repository.updateAppointment(appointment);

      // SMAP-28: reschedule local reminder
      await NotificationService.cancelAppointmentReminder(
        appointment.id.hashCode,
      );
      await _scheduleReminder(appointment);

      // FCM: notify patient + family of updated time
      if (appointment.patientId != null) {
        await FcmService.notifyAppointment(
          patientId: appointment.patientId!,
          appointmentTitle: appointment.title,
          doctorName: appointment.doctorName,
          appointmentDateTime: appointment.appointmentDateTime,
          appointmentId: appointment.id,
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