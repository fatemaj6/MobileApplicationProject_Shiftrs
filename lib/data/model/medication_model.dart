import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationModel {
  final String id;
  final String caregiverId;
  final String patientId;
  final String name;
  final String dosage;
  final String frequency;
  final String time;
  final String instructions;
  final String status; // pending, given, missed
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final bool isDeleted;

  MedicationModel({
    required this.id,
    required this.caregiverId,
    required this.patientId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.time,
    this.instructions = '',
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  /// Create a MedicationModel from a Firestore document snapshot
  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicationModel(
      id: doc.id,
      caregiverId: data['caregiverId'] ?? '',
      patientId: data['patientId'] ?? '',
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      frequency: data['frequency'] ?? '',
      time: data['time'] ?? '',
      instructions: data['instructions'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  /// Convert a MedicationModel to a Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'caregiverId': caregiverId,
      'patientId': patientId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'time': time,
      'instructions': instructions,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isDeleted': isDeleted,
    };
  }

  /// Return a copy of this model with updated fields
  MedicationModel copyWith({
    String? id,
    String? caregiverId,
    String? patientId,
    String? name,
    String? dosage,
    String? frequency,
    String? time,
    String? instructions,
    String? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isDeleted,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      time: time ?? this.time,
      instructions: instructions ?? this.instructions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}