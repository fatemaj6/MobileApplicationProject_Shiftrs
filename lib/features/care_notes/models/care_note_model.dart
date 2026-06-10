import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CareNoteModel {
  final String id;
  final String caregiverId;
  final String? patientId;

  final DateTime date;

  // NEW fields
  final String category; // Vitals, Meals, Mood, Sleep, General
  final String title;

  // OLD fields - keep them so your friends' code still works
  final String meals;
  final String mood;
  final int? systolic;
  final int? diastolic;
  final double? sleepHours;
  final String notes;

  final bool isDeleted;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  CareNoteModel({
    required this.id,
    required this.caregiverId,
    this.patientId,
    required this.date,
    this.category = 'General',
    this.title = '',
    this.meals = '',
    this.mood = '',
    this.systolic,
    this.diastolic,
    this.sleepHours,
    this.notes = '',
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  String get formattedDate => DateFormat('EEE, d MMM yyyy').format(date);
  String get dayNumber => DateFormat('d').format(date);
  String get shortMonth => DateFormat('MMM').format(date);

  String get bloodPressureText {
    if (systolic == null || diastolic == null) return '—';
    return '$systolic/$diastolic';
  }

  String get sleepText => sleepHours == null ? '—' : '$sleepHours h';

  String get displayTitle {
    if (title.trim().isNotEmpty) return title;

    switch (category) {
      case 'Vitals':
        return 'Blood Pressure';
      case 'Meals':
        return 'Meal Note';
      case 'Mood':
        return 'Mood Note';
      case 'Sleep':
        return 'Sleep Note';
      default:
        return 'Care Note';
    }
  }

  String get summaryText {
    switch (category) {
      case 'Vitals':
        return bloodPressureText;
      case 'Meals':
        return meals;
      case 'Mood':
        return mood.isNotEmpty ? mood : notes;
      case 'Sleep':
        return sleepText;
      default:
        return notes;
    }
  }

  factory CareNoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CareNoteModel.fromMap(data, id: doc.id);
  }

  factory CareNoteModel.fromMap(Map<String, dynamic> data, {String id = ''}) {
    DateTime dt = DateTime.now();

    if (data['date'] is Timestamp) {
      dt = (data['date'] as Timestamp).toDate();
    }

    return CareNoteModel(
      id: id.isNotEmpty ? id : (data['id'] ?? ''),
      caregiverId: data['caregiverId'] ?? '',
      patientId: data['patientId'],
      date: dt,

      // NEW fields, with safe defaults for old notes
      category: data['category'] ?? 'General',
      title: data['title'] ?? '',

      // OLD fields
      meals: data['meals'] ?? '',
      mood: data['mood'] ?? '',
      systolic: (data['systolic'] as num?)?.toInt(),
      diastolic: (data['diastolic'] as num?)?.toInt(),
      sleepHours: (data['sleepHours'] as num?)?.toDouble(),
      notes: data['notes'] ?? '',
      isDeleted: data['isDeleted'] ?? false,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'caregiverId': caregiverId,
      'patientId': patientId,
      'date': Timestamp.fromDate(date),

      // NEW fields
      'category': category,
      'title': title,

      // OLD fields
      'meals': meals,
      'mood': mood,
      'systolic': systolic,
      'diastolic': diastolic,
      'sleepHours': sleepHours,
      'notes': notes,

      'isDeleted': isDeleted,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CareNoteModel copyWith({
    String? id,
    String? caregiverId,
    String? patientId,
    DateTime? date,
    String? category,
    String? title,
    String? meals,
    String? mood,
    int? systolic,
    int? diastolic,
    double? sleepHours,
    String? notes,
    bool? isDeleted,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return CareNoteModel(
      id: id ?? this.id,
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      date: date ?? this.date,
      category: category ?? this.category,
      title: title ?? this.title,
      meals: meals ?? this.meals,
      mood: mood ?? this.mood,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      sleepHours: sleepHours ?? this.sleepHours,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}