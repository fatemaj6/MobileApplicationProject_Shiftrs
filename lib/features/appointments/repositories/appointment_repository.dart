import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment_model.dart';

class AppointmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'appointments';

  /// Live stream of all appointments for a caregiver.
  /// We filter and sort in Dart to avoid Firestore composite index error.
  Stream<List<AppointmentModel>> streamAppointmentsForCaregiver(
    String caregiverId,
  ) {
    return _firestore
        .collection(_collection)
        .where('caregiverId', isEqualTo: caregiverId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .where((appointment) => appointment.isDeleted == false)
          .toList();

      appointments.sort(
        (a, b) => a.appointmentDateTime.compareTo(b.appointmentDateTime),
      );

      return appointments;
    });
  }

  /// One-time fetch of all appointments for a caregiver.
  /// We filter and sort in Dart to avoid Firestore composite index error.
  Future<List<AppointmentModel>> getAppointmentsForCaregiver(
    String caregiverId,
  ) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('caregiverId', isEqualTo: caregiverId)
        .get();

    final appointments = snapshot.docs
        .map((doc) => AppointmentModel.fromFirestore(doc))
        .where((appointment) => appointment.isDeleted == false)
        .toList();

    appointments.sort(
      (a, b) => a.appointmentDateTime.compareTo(b.appointmentDateTime),
    );

    return appointments;
  }

  /// Add a new appointment document.
  Future<void> addAppointment(AppointmentModel appointment) async {
    await _firestore.collection(_collection).add(appointment.toMap());
  }

  /// Update an existing appointment document.
  Future<void> updateAppointment(AppointmentModel appointment) async {
    await _firestore
        .collection(_collection)
        .doc(appointment.id)
        .update(appointment.toMap());
  }

  /// Soft delete: set isDeleted = true.
  Future<void> deleteAppointment(String appointmentId) async {
    await _firestore.collection(_collection).doc(appointmentId).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get a single appointment by ID.
  Future<AppointmentModel?> getAppointment(String appointmentId) async {
    final doc = await _firestore.collection(_collection).doc(appointmentId).get();
    if (!doc.exists) return null;
    return AppointmentModel.fromFirestore(doc);
  }

  /// Get all appointments for caregiver including soft-deleted ones.
  Future<List<AppointmentModel>> getAppointmentsIncludingDeleted(String caregiverId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('caregiverId', isEqualTo: caregiverId)
        .get();

    return snapshot.docs
        .map((doc) => AppointmentModel.fromFirestore(doc))
        .toList();
  }
}