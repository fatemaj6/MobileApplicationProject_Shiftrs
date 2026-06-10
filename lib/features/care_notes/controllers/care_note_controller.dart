import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/care_note_model.dart';
import '../repositories/care_note_repository.dart';

class CareNoteController extends ChangeNotifier {
  final CareNoteRepository _repository = CareNoteRepository();

  bool isLoading = false;
  String? errorMessage;

  String get caregiverId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<List<CareNoteModel>> streamCareNotes({String? caregiverIdOverride}) {
    final id = caregiverIdOverride ?? caregiverId;
    return _repository.streamCareNotesForCaregiver(id);
  }

  Future<bool> addCareNote(CareNoteModel note) async {
    _setLoading(true);
    try {
      final withCaregiver = note.copyWith(caregiverId: caregiverId);
      await _repository.addCareNote(withCaregiver);
      return true;
    } catch (e) {
      errorMessage = 'Failed to add care note: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCareNote(CareNoteModel note) async {
    _setLoading(true);
    try {
      await _repository.updateCareNote(note);
      return true;
    } catch (e) {
      errorMessage = 'Failed to update care note: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCareNote(String noteId) async {
    try {
      await _repository.deleteCareNote(noteId);
      return true;
    } catch (e) {
      errorMessage = 'Failed to delete care note: $e';
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}