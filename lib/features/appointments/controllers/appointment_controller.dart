import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';

class AppointmentController extends ChangeNotifier {
  final AppointmentRepository _repository = AppointmentRepository();

  bool isLoading = false;
  String? errorMessage;

  /// The current caregiver's Firebase UID.
  String get caregiverId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ─── Stream ───────────────────────────────────────────────────────────────

  Stream<List<AppointmentModel>> streamAppointments() {
    return _repository.streamAppointmentsForCaregiver(caregiverId);
  }

  // ─── Add ──────────────────────────────────────────────────────────────────

  Future<bool> addAppointment(AppointmentModel appointment) async {
    _setLoading(true);
    try {
      final withCaregiver =
          appointment.copyWith(caregiverId: caregiverId);
      await _repository.addAppointment(withCaregiver);
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
      return true;
    } catch (e) {
      errorMessage = 'Failed to delete appointment: $e';
      notifyListeners();
      return false;
    }
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