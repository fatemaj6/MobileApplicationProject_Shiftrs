import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../features/appointments/models/appointment_model.dart';
import '../../../data/model/medication_model.dart';
import '../models/care_report_model.dart';

/// Controller for SMAP-34: Generate Care Summary Report.
///
/// Reuses data from the existing [appointments] and [medications] Firestore
/// collections — no new collections are created.
class CareReportController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  String? errorMessage;
  CareReportModel? report;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Generates a care summary report for the current caregiver for the
  /// supplied [startDate]–[endDate] range (both inclusive).
  ///
  /// Appointments are filtered by [appointmentDateTime].
  /// Medications are filtered by [createdAt] (when the record was created).
  Future<bool> generateReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_uid.isEmpty) {
      errorMessage = 'You must be logged in to generate a report.';
      notifyListeners();
      return false;
    }

    // Normalise: start of startDate, end of endDate
    final from = DateTime(startDate.year, startDate.month, startDate.day);
    final to = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    if (from.isAfter(to)) {
      errorMessage = 'Start date must be on or before the end date.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _fetchAppointments(from, to),
        _fetchMedications(from, to),
      ]);

      final appointments = results[0] as List<AppointmentModel>;
      final medications = results[1] as List<MedicationModel>;

      report = CareReportModel(
        startDate: from,
        endDate: to,
        generatedBy: _uid,
        appointments: appointments,
        medications: medications,
      );

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Failed to generate report: $e';
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  Future<List<AppointmentModel>> _fetchAppointments(
    DateTime from,
    DateTime to,
  ) async {
    // Fetch all caregiver appointments then filter locally to avoid
    // composite-index requirements (consistent with existing repository pattern).
    final snapshot = await _firestore
        .collection('appointments')
        .where('caregiverId', isEqualTo: _uid)
        .get();

    return snapshot.docs
        .map((doc) => AppointmentModel.fromFirestore(doc))
        .where((a) =>
            !a.isDeleted &&
            !a.appointmentDateTime.isBefore(from) &&
            !a.appointmentDateTime.isAfter(to))
        .toList()
      ..sort((a, b) => a.appointmentDateTime.compareTo(b.appointmentDateTime));
  }

  Future<List<MedicationModel>> _fetchMedications(
    DateTime from,
    DateTime to,
  ) async {
    // Fetch medications by caregiverId (same pattern as existing repo), then
    // filter by createdAt locally.
    final snapshot = await _firestore
        .collection('medications')
        .where('caregiverId', isEqualTo: _uid)
        .get();

    return snapshot.docs
        .map((doc) => MedicationModel.fromFirestore(doc))
        .where((m) {
          if (m.isDeleted) return false;
          if (m.createdAt == null) return true; // include if no timestamp
          final createdDate = m.createdAt!.toDate();
          return !createdDate.isBefore(from) && !createdDate.isAfter(to);
        })
        .toList()
      ..sort((a, b) {
        final aDate = a.createdAt?.toDate();
        final bDate = b.createdAt?.toDate();
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });
  }

  // ─── Validation ───────────────────────────────────────────────────────────

  /// Returns an error string or null.  Used by the form before calling
  /// [generateReport].
  String? validateDateRange(DateTime? start, DateTime? end) {
    if (start == null) return 'Please select a start date.';
    if (end == null) return 'Please select an end date.';
    if (start.isAfter(end)) return 'Start date must be before end date.';
    return null;
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void clearReport() {
    report = null;
    errorMessage = null;
    notifyListeners();
  }
}
