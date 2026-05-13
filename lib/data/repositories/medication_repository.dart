import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/medication_model.dart';

class MedicationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'medications';

  /// Stream all non-deleted medications for a given patient
  Stream<List<MedicationModel>> getMedications({
    required String patientId,
  }) {
    return _firestore
        .collection(_collection)
        .where('patientId', isEqualTo: patientId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicationModel.fromFirestore(doc))
            .toList());
  }

  /// Add a new medication document to Firestore
  Future<void> addMedication(MedicationModel medication) async {
    await _firestore.collection(_collection).add(medication.toFirestore());
  }

  /// Update an existing medication document
  Future<void> updateMedication(MedicationModel medication) async {
    await _firestore
        .collection(_collection)
        .doc(medication.id)
        .update(medication.toFirestore());
  }

  /// Update only the status field and updatedAt timestamp
  Future<void> updateMedicationStatus(
      String medicationId, String status) async {
    await _firestore.collection(_collection).doc(medicationId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Soft delete: set isDeleted = true instead of removing the document
  Future<void> deleteMedication(String medicationId) async {
    await _firestore.collection(_collection).doc(medicationId).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}