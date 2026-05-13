import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/medication_model.dart';

class MedicationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'medications';

  /// Stream all non-deleted medications for a given patient.
  /// 
  /// Important:
  /// We only use one Firestore where filter to avoid requiring a composite index.
  /// Then we filter isDeleted and sort locally in Dart.
  Stream<List<MedicationModel>> getMedications({
    required String patientId,
  }) {
    return _firestore
        .collection(_collection)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final medications = snapshot.docs
          .map((doc) => MedicationModel.fromFirestore(doc))
          .where((medication) => medication.isDeleted == false)
          .toList();

      medications.sort((a, b) {
        final aDate = a.createdAt?.toDate();
        final bDate = b.createdAt?.toDate();

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return aDate.compareTo(bDate);
      });

      return medications;
    });
  }

  /// Add a new medication document to Firestore.
  Future<void> addMedication(MedicationModel medication) async {
    await _firestore.collection(_collection).add(medication.toFirestore());
  }

  /// Update an existing medication document.
  Future<void> updateMedication(MedicationModel medication) async {
    await _firestore.collection(_collection).doc(medication.id).update({
      'caregiverId': medication.caregiverId,
      'patientId': medication.patientId,
      'name': medication.name,
      'dosage': medication.dosage,
      'frequency': medication.frequency,
      'time': medication.time,
      'instructions': medication.instructions,
      'status': medication.status,
      'updatedAt': FieldValue.serverTimestamp(),
      'isDeleted': medication.isDeleted,
    });
  }

  /// Update only the status field and updatedAt timestamp.
  Future<void> updateMedicationStatus(
    String medicationId,
    String status,
  ) async {
    await _firestore.collection(_collection).doc(medicationId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Soft delete: set isDeleted = true instead of removing the document.
  Future<void> deleteMedication(String medicationId) async {
    await _firestore.collection(_collection).doc(medicationId).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}