import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';

import '../../../data/model/medication_model.dart';
import '../../../data/services/ai_service.dart';
import '../../care_notes/repositories/care_note_repository.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

// pulls patient's recent care notes + current medications from firestore
// hands them to the model as context, and runs a multi-turn chat
class AiAssistantController extends ChangeNotifier {
  AiAssistantController({String? patientName}) : _patientName = patientName;

  final AiService _ai = AiService();
  final CareNoteRepository _careNotes = CareNoteRepository();

  final String? _patientName;

  final List<ChatMessage> messages = [];
  bool isLoading = false;
  String? errorMessage;

  ChatSession? _chat;

  String get _caregiverId => FirebaseAuth.instance.currentUser?.uid ?? '';

  bool get hasConversation => messages.isNotEmpty;

  // send a user message and append the assistant's reply.
  Future<void> send(String input) async {
    final text = input.trim();
    if (text.isEmpty || isLoading) return;

    messages.add(ChatMessage(text: text, isUser: true));
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _ensureChatStarted();
      final response = await _chat!.sendMessage(Content.text(text));
      final reply = response.text?.trim() ?? '';
      messages.add(
        ChatMessage(
          text: reply.isEmpty
              ? "Sorry, I couldn't put together a response. Try rephrasing?"
              : reply,
          isUser: false,
        ),
      );
    } catch (e) {
      errorMessage = _friendlyError(e);
      messages.add(ChatMessage(text: errorMessage!, isUser: false));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  //clear conversation
  void reset() {
    messages.clear();
    _chat = null;
    errorMessage = null;
    notifyListeners();
  }

  //helpers----------------------------------------------------------------------------
  Future<void> _ensureChatStarted() async {
    if (_chat != null) return;
    final context = await _buildContext();
    _chat = _ai.startChat(systemInstruction: _systemInstruction(context));
  }

  String _systemInstruction(String patientContext) {
    final name = (_patientName == null || _patientName!.trim().isEmpty)
        ? 'the patient'
        : _patientName!.trim();

    return '''
You are an assistant of a health tracking app. You help a caregiver or family
member understand the day-to-day care of the patient. Be concise, use plain
language a medically untrained person can follow.

Safety rules you must always follow:
- You are NOT a doctor. Your answers are general information only and must not
  replace professional medical advice, diagnosis, or treatment.
- Never diagnose conditions, and never prescribe or adjust medication.
- For questions about medication interactions, dosages, or worrying symptoms,
  give general information and clearly advise confirming with a doctor or
  pharmacist.
- If something sounds urgent or serious, advise contacting a healthcare
  provider or emergency services.
- If you lack the information to answer well, say so and ask a short
  clarifying question instead of guessing.
- Answer concisely, if possible in 1-4 sentences. If the question is broad, give a brief overview and suggest one or two
  specific follow-up questions to narrow down the answer.

Use the care data below when relevant. If it doesn't cover the question, answer
generally and note that the records don't show it.

$patientContext
''';
  }

  Future<String> _buildContext() async {
    final buffer = StringBuffer();

    // Recent care notes (repository already sorts newest-first).
    try {
      final notes = await _careNotes
          .streamCareNotesForCaregiver(_caregiverId)
          .first;
      final recent = notes.take(7).toList();
      if (recent.isEmpty) {
        buffer.writeln('Recent care notes: none recorded yet.');
      } else {
        buffer.writeln('Recent care notes (newest first):');
        for (final n in recent) {
          buffer.writeln(
            '- ${n.formattedDate}: blood pressure ${n.bloodPressureText}, '
            'mood "${n.mood.isEmpty ? 'n/a' : n.mood}", sleep ${n.sleepText}, '
            'meals "${n.meals.isEmpty ? 'n/a' : n.meals}". '
            'Notes: ${n.notes.isEmpty ? 'none' : n.notes}',
          );
        }
      }
    } catch (_) {
      buffer.writeln('Recent care notes: unavailable.');
    }

    // Current medications (single-field query, no composite index required).
    try {
      final meds = await _fetchMedications();
      if (meds.isEmpty) {
        buffer.writeln('\nMedications: none recorded.');
      } else {
        buffer.writeln('\nMedications:');
        for (final m in meds) {
          buffer.writeln(
            '- ${m.name} ${m.dosage}, ${m.frequency} at ${m.time} '
            '(status: ${m.status})'
            '${m.instructions.isEmpty ? '' : ', instructions: ${m.instructions}'}',
          );
        }
      }
    } catch (_) {
      buffer.writeln('\nMedications: unavailable.');
    }

    return buffer.toString();
  }

  Future<List<MedicationModel>> _fetchMedications() async {
    if (_caregiverId.isEmpty) return [];
    final snap = await FirebaseFirestore.instance
        .collection('medications')
        .where('caregiverId', isEqualTo: _caregiverId)
        .get();
    return snap.docs
        .map((d) => MedicationModel.fromFirestore(d))
        .where((m) => !m.isDeleted)
        .toList();
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('quota') ||
        msg.contains('429') ||
        msg.contains('resource_exhausted')) {
      return "The assistant has reached today's free-tier limit. "
          'Please try again later.';
    }
    return 'Sorry, something went wrong reaching the assistant. '
        'Please check your connection and try again.';
  }
}
