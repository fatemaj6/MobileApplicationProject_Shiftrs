import 'package:flutter/foundation.dart';
import '../../../data/model/medication_model.dart';
import '../../../data/repositories/medication_repository.dart';

class MedicationController extends ChangeNotifier {
  final MedicationRepository _repository = MedicationRepository();

  bool isLoading = false;
  String? errorMessage;

  // ─── Stream ───────────────────────────────────────────────────────────────

  /// Returns a live stream of medications for the given patient.
  Stream<List<MedicationModel>> getMedicationsStream(String patientId) {
    return _repository.getMedications(patientId: patientId);
  }

  // ─── Add ──────────────────────────────────────────────────────────────────

  /// Saves a new medication to Firestore.
  /// Returns true on success, false on failure.
  Future<bool> addMedication(MedicationModel medication) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.addMedication(medication);
      return true;
    } catch (e) {
      errorMessage = 'Failed to add medication: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ─── Edit ─────────────────────────────────────────────────────────────────

  /// Updates an existing medication document in Firestore.
  Future<bool> updateMedication(MedicationModel medication) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateMedication(medication);
      return true;
    } catch (e) {
      errorMessage = 'Failed to update medication: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ─── Status helpers ───────────────────────────────────────────────────────

  /// Marks a medication as "given".
  Future<bool> markAsGiven(String medicationId) async {
    return _updateStatus(medicationId, 'given');
  }

  /// Marks a medication as "missed".
  Future<bool> markAsMissed(String medicationId) async {
    return _updateStatus(medicationId, 'missed');
  }

  Future<bool> _updateStatus(String medicationId, String status) async {
    try {
      await _repository.updateMedicationStatus(medicationId, status);
      return true;
    } catch (e) {
      errorMessage = 'Failed to update status: $e';
      notifyListeners();
      return false;
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  /// Soft-deletes a medication (sets isDeleted = true).
  Future<bool> deleteMedication(String medicationId) async {
    try {
      await _repository.deleteMedication(medicationId);
      return true;
    } catch (e) {
      errorMessage = 'Failed to delete medication: $e';
      notifyListeners();
      return false;
    }
  }

  // ─── Validation ───────────────────────────────────────────────────────────

  /// Returns an error string if the field is empty, otherwise null.
  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}