import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/care_note_model.dart';

class CareNoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'care_notes';

  Stream<List<CareNoteModel>> streamCareNotesForCaregiver(String caregiverId) {
    return _firestore
        .collection(_collection)
        .where('caregiverId', isEqualTo: caregiverId)
        .snapshots()
        .map((snapshot) {
          final notes = snapshot.docs
              .map((doc) => CareNoteModel.fromFirestore(doc))
              .where((note) => note.isDeleted == false)
              .toList();

          notes.sort((a, b) => b.date.compareTo(a.date)); // newest first
          return notes;
        });
  }

  Future<void> addCareNote(CareNoteModel note) async {
    await _firestore.collection(_collection).add(note.toMap());
  }

  Future<void> updateCareNote(CareNoteModel note) async {
    await _firestore.collection(_collection).doc(note.id).update(note.toMap());
  }

  Future<void> deleteCareNote(String noteId) async {
    //soft delete
    await _firestore.collection(_collection).doc(noteId).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<CareNoteModel?> getCareNote(String noteId) async {
    final doc = await _firestore.collection(_collection).doc(noteId).get();
    if (!doc.exists) return null;
    return CareNoteModel.fromFirestore(doc);
  }
}
