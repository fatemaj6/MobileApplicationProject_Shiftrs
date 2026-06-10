import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppointmentModel {
  final String id;
  final String caregiverId;
  final String? patientId;
  final String title;
  final String clinicName;
  final String clinicAddress; // ← SMAP-31
  final String doctorName;
  final String specialty;
  final String appointmentType;
  final DateTime appointmentDateTime;
  final String notes;
  final String status; // upcoming, past, cancelled
  final bool isDeleted;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String? googleEventId;
  final String? googleEventSyncState;

  AppointmentModel({
    required this.id,
    required this.caregiverId,
    this.patientId,
    required this.title,
    required this.clinicName,
    this.clinicAddress = '', // ← SMAP-31
    this.doctorName = '',
    this.specialty = '',
    required this.appointmentType,
    required this.appointmentDateTime,
    this.notes = '',
    this.status = 'upcoming',
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.googleEventId,
    this.googleEventSyncState,
  });

  bool get isPast => appointmentDateTime.isBefore(DateTime.now());

  String get formattedDate =>
      DateFormat('EEE, d MMM').format(appointmentDateTime);

  String get formattedDateLong =>
      DateFormat('EEE, d MMM yyyy').format(appointmentDateTime);

  String get formattedTime =>
      DateFormat('h:mm a').format(appointmentDateTime);

  String get dayNumber => DateFormat('d').format(appointmentDateTime);

  String get shortMonth => DateFormat('MMM').format(appointmentDateTime);

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel.fromMap(data, id: doc.id);
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> data,
      {String id = ''}) {
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
      clinicAddress: data['clinicAddress'] ?? '', // ← SMAP-31
      doctorName: data['doctorName'] ?? '',
      specialty: data['specialty'] ?? '',
      appointmentType: data['appointmentType'] ?? 'Check-up',
      appointmentDateTime: dt,
      notes: data['notes'] ?? '',
      status: data['status'] ?? 'upcoming',
      isDeleted: data['isDeleted'] ?? false,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
      googleEventId: data['googleEventId'] as String?,
      googleEventSyncState: data['googleEventSyncState'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'caregiverId': caregiverId,
      'patientId': patientId,
      'title': title,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress, // ← SMAP-31
      'doctorName': doctorName,
      'specialty': specialty,
      'appointmentType': appointmentType,
      'appointmentDateTime': Timestamp.fromDate(appointmentDateTime),
      'notes': notes,
      'status': status,
      'isDeleted': isDeleted,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'googleEventId': googleEventId,
      'googleEventSyncState': googleEventSyncState,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? caregiverId,
    String? patientId,
    String? title,
    String? clinicName,
    String? clinicAddress, // ← SMAP-31
    String? doctorName,
    String? specialty,
    String? appointmentType,
    DateTime? appointmentDateTime,
    String? notes,
    String? status,
    bool? isDeleted,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? googleEventId,
    String? googleEventSyncState,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress, // ← SMAP-31
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      appointmentType: appointmentType ?? this.appointmentType,
      appointmentDateTime: appointmentDateTime ?? this.appointmentDateTime,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      googleEventId: googleEventId ?? this.googleEventId,
      googleEventSyncState: googleEventSyncState ?? this.googleEventSyncState,
    );
  }
}