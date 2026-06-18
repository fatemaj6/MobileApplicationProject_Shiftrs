import 'package:cloud_firestore/cloud_firestore.dart';

class HealthAlertModel {
  final String id;
  final String caregiverId;
  final String? patientId;
  final String type;
  final String title;
  final String message;
  final String severity;
  final String source;
  final bool isRead;
  final Timestamp? createdAt;

  HealthAlertModel({
    required this.id,
    required this.caregiverId,
    this.patientId,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.source,
    this.isRead = false,
    this.createdAt,
  });

  factory HealthAlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return HealthAlertModel(
      id: doc.id,
      caregiverId: data['caregiverId'] ?? '',
      patientId: data['patientId'],
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      severity: data['severity'] ?? 'low',
      source: data['source'] ?? 'care_note',
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'caregiverId': caregiverId,
      'patientId': patientId,
      'type': type,
      'title': title,
      'message': message,
      'severity': severity,
      'source': source,
      'isRead': isRead,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}