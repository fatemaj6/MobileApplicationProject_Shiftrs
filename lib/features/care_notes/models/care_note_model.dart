import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CareNoteModel {
  final String id;
  final String caregiverId;
  final String? patientId;
  final DateTime date; // the day this record is for
  final String meals; // free-text description
  final String mood; // one of the mood options
  final int? systolic;
  final int? diastolic;
  final double? sleepHours;
  final String notes; //anything else
  final bool isDeleted;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  CareNoteModel({
    required this.id,
    required this.caregiverId,
    this.patientId,
    required this.date,
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
    //write into firebase
    return {
      'caregiverId': caregiverId,
      'patientId': patientId,
      'date': Timestamp.fromDate(date),
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
