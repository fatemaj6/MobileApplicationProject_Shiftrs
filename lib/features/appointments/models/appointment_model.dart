import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppointmentModel {
  final String id;
  final String caregiverId;
  final String? patientId;
  final String title;
  final String clinicName;
  final String doctorName;
  final String specialty;
  final String appointmentType;
  final DateTime appointmentDateTime;
  final String notes;
  final String status; // upcoming, past, cancelled
  final bool isDeleted;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  AppointmentModel({
    required this.id,
    required this.caregiverId,
    this.patientId,
    required this.title,
    required this.clinicName,
    this.doctorName = '',
    this.specialty = '',
    required this.appointmentType,
    required this.appointmentDateTime,
    this.notes = '',
    this.status = 'upcoming',
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  /// True if the appointment date/time is before now
  bool get isPast => appointmentDateTime.isBefore(DateTime.now());

  /// e.g. "Sat, 30 May"
  String get formattedDate =>
      DateFormat('EEE, d MMM').format(appointmentDateTime);

  /// e.g. "Fri, 10 Apr 2026"
  String get formattedDateLong =>
      DateFormat('EEE, d MMM yyyy').format(appointmentDateTime);

  /// e.g. "10:00 AM"
  String get formattedTime =>
      DateFormat('h:mm a').format(appointmentDateTime);

  /// Day number, e.g. "10"
  String get dayNumber => DateFormat('d').format(appointmentDateTime);

  /// Short month, e.g. "Apr"
  String get shortMonth => DateFormat('MMM').format(appointmentDateTime);

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel.fromMap(data, id: doc.id);
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> data,
      {String id = ''}) {
    // appointmentDateTime is stored as a Firestore Timestamp
    DateTime dt = DateTime.now();
    if (data['appointmentDateTime'] != null) {
      if (data['appointmentDateTime'] is Timestamp) {
        dt = (data['appointmentDateTime'] as Timestamp).toDate();
      }
    }

    return AppointmentModel(
      id: id.isNotEmpty ? id : (data['id'] ?? ''),
      caregiverId: data['caregiverId'] ?? '',
      patientId: data['patientId'],
      title: data['title'] ?? '',
      clinicName: data['clinicName'] ?? '',
      doctorName: data['doctorName'] ?? '',
      specialty: data['specialty'] ?? '',
      appointmentType: data['appointmentType'] ?? 'Check-up',
      appointmentDateTime: dt,
      notes: data['notes'] ?? '',
      status: data['status'] ?? 'upcoming',
      isDeleted: data['isDeleted'] ?? false,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'caregiverId': caregiverId,
      'patientId': patientId,
      'title': title,
      'clinicName': clinicName,
      'doctorName': doctorName,
      'specialty': specialty,
      'appointmentType': appointmentType,
      'appointmentDateTime': Timestamp.fromDate(appointmentDateTime),
      'notes': notes,
      'status': status,
      'isDeleted': isDeleted,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? caregiverId,
    String? patientId,
    String? title,
    String? clinicName,
    String? doctorName,
    String? specialty,
    String? appointmentType,
    DateTime? appointmentDateTime,
    String? notes,
    String? status,
    bool? isDeleted,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      clinicName: clinicName ?? this.clinicName,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      appointmentType: appointmentType ?? this.appointmentType,
      appointmentDateTime: appointmentDateTime ?? this.appointmentDateTime,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}