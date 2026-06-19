import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/health_alert_model.dart';

class HealthAlertRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<HealthAlertModel>> streamAlertsForCaregiver(String caregiverId) {
    final careNotesStream = _firestore
        .collection('care_notes')
        .where('caregiverId', isEqualTo: caregiverId)
        .where('isDeleted', isEqualTo: false)
        .snapshots();

    final medicationsStream = _firestore
        .collection('medications')
        .where('caregiverId', isEqualTo: caregiverId)
        .where('isDeleted', isEqualTo: false)
        .snapshots();

    final appointmentsStream = _firestore
        .collection('appointments')
        .where('caregiverId', isEqualTo: caregiverId)
        .where('isDeleted', isEqualTo: false)
        .snapshots();

    return _combineLatest3(
      careNotesStream,
      medicationsStream,
      appointmentsStream,
      (careNotes, medications, appointments) {
        final alerts = <HealthAlertModel>[];

        alerts.addAll(_buildCareNoteAlerts(caregiverId, careNotes.docs));
        alerts.addAll(_buildMedicationAlerts(caregiverId, medications.docs));
        alerts.addAll(_buildAppointmentAlerts(caregiverId, appointments.docs));

        alerts.sort((a, b) {
          final aDate = a.createdAt?.toDate() ?? DateTime(2000);
          final bDate = b.createdAt?.toDate() ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });

        return alerts;
      },
    );
  }

  List<HealthAlertModel> _buildCareNoteAlerts(
    String caregiverId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final alerts = <HealthAlertModel>[];

    final notes = docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'id': doc.id,
      };
    }).toList();

    notes.sort((a, b) {
      final aDate = _dateFromValue(a['date']);
      final bDate = _dateFromValue(b['date']);
      return bDate.compareTo(aDate);
    });

    for (final note in notes) {
      final systolic = (note['systolic'] as num?)?.toInt();
      final diastolic = (note['diastolic'] as num?)?.toInt();
      final sleepHours = (note['sleepHours'] as num?)?.toDouble();
      final patientId = note['patientId'] as String?;
      final noteDate = _dateFromValue(note['date']);
      final noteTimestamp = Timestamp.fromDate(noteDate);
      final noteId = note['id'] ?? '';

      if (systolic != null && diastolic != null) {
        if (systolic >= 180 || diastolic >= 120) {
          alerts.add(
            _alert(
              id: 'bp-high-$noteId',
              caregiverId: caregiverId,
              patientId: patientId,
              type: 'blood_pressure',
              title: 'Very High Blood Pressure',
              message:
                  'Blood pressure reading $systolic/$diastolic is very high and may need urgent attention.',
              severity: 'high',
              source: 'care_note',
              createdAt: noteTimestamp,
            ),
          );
        } else if (systolic >= 140 || diastolic >= 90) {
          alerts.add(
            _alert(
              id: 'bp-medium-$noteId',
              caregiverId: caregiverId,
              patientId: patientId,
              type: 'blood_pressure',
              title: 'High Blood Pressure',
              message:
                  'Blood pressure reading $systolic/$diastolic is above the normal range.',
              severity: 'medium',
              source: 'care_note',
              createdAt: noteTimestamp,
            ),
          );
        }
      }

      if (sleepHours != null && sleepHours < 4) {
        alerts.add(
          _alert(
            id: 'sleep-low-$noteId',
            caregiverId: caregiverId,
            patientId: patientId,
            type: 'sleep_low',
            title: 'Low Sleep Recorded',
            message:
                'Only $sleepHours hours of sleep were recorded. Please monitor the patient’s rest.',
            severity: 'medium',
            source: 'care_note',
            createdAt: noteTimestamp,
          ),
        );
      }

      final text = '${note['title'] ?? ''} ${note['notes'] ?? ''}'
          .toLowerCase();

      final keywords = [
        'pain',
        'dizzy',
        'fall',
        'weak',
        'fever',
        'vomit',
        'nausea',
        'headache',
      ];

      final foundKeyword = keywords.firstWhere(
        (word) => text.contains(word),
        orElse: () => '',
      );

      if (foundKeyword.isNotEmpty) {
        alerts.add(
          _alert(
            id: 'symptom-$noteId',
            caregiverId: caregiverId,
            patientId: patientId,
            type: 'symptom_keyword',
            title: 'Possible Symptom Mentioned',
            message:
                'The care note mentions "$foundKeyword", which may need attention.',
            severity: 'low',
            source: 'care_note',
            createdAt: noteTimestamp,
          ),
        );
      }
    }

    final concerningMoods = [
      'anxious',
      'sad',
      'irritable',
      'unwell',
    ];

    final moodNotes = notes.where((note) {
      final mood = (note['mood'] ?? '').toString().toLowerCase().trim();
      return mood.isNotEmpty;
    }).toList();

    final recentThreeMoodNotes = moodNotes.take(3).toList();

    if (recentThreeMoodNotes.length == 3) {
      final allConcerning = recentThreeMoodNotes.every((note) {
        final mood = (note['mood'] ?? '').toString().toLowerCase().trim();
        return concerningMoods.contains(mood);
      });

      if (allConcerning) {
        final newest = recentThreeMoodNotes.first;
        alerts.add(
          _alert(
            id: 'mood-pattern-${newest['id']}',
            caregiverId: caregiverId,
            patientId: newest['patientId'] as String?,
            type: 'mood_pattern',
            title: 'Repeated Mood Concern',
            message:
                'The patient has had concerning mood entries for 3 recent care notes.',
            severity: 'medium',
            source: 'care_note',
            createdAt: Timestamp.fromDate(_dateFromValue(newest['date'])),
          ),
        );
      }
    }

    return alerts;
  }

  List<HealthAlertModel> _buildMedicationAlerts(
    String caregiverId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final alerts = <HealthAlertModel>[];

    final missedMeds = docs.where((doc) {
      final status = (doc.data()['status'] ?? '').toString().toLowerCase();
      return status == 'missed';
    }).toList();

    if (missedMeds.length >= 2) {
      alerts.add(
        _alert(
          id: 'missed-medications-pattern',
          caregiverId: caregiverId,
          patientId: missedMeds.first.data()['patientId'] as String?,
          type: 'missed_medication',
          title: 'Repeated Missed Medications',
          message:
              '${missedMeds.length} medication(s) are marked as missed. Please review medication adherence.',
          severity: missedMeds.length >= 3 ? 'high' : 'medium',
          source: 'medication',
          createdAt: Timestamp.now(),
        ),
      );
    }

    return alerts;
  }

  List<HealthAlertModel> _buildAppointmentAlerts(
    String caregiverId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final alerts = <HealthAlertModel>[];
    final now = DateTime.now();
    final next7Days = now.add(const Duration(days: 7));

    final upcomingAppointments = docs.where((doc) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();
      final date = _dateFromValue(data['appointmentDateTime']);

      return status != 'cancelled' &&
          date.isAfter(now) &&
          date.isBefore(next7Days);
    }).toList();

    if (upcomingAppointments.length >= 3) {
      alerts.add(
        _alert(
          id: 'appointment-load',
          caregiverId: caregiverId,
          patientId: upcomingAppointments.first.data()['patientId'] as String?,
          type: 'appointment_load',
          title: 'Many Upcoming Appointments',
          message:
              '${upcomingAppointments.length} appointments are scheduled within the next 7 days.',
          severity: 'low',
          source: 'appointment',
          createdAt: Timestamp.now(),
        ),
      );
    }

    return alerts;
  }

  HealthAlertModel _alert({
    required String id,
    required String caregiverId,
    required String? patientId,
    required String type,
    required String title,
    required String message,
    required String severity,
    required String source,
    required Timestamp createdAt,
  }) {
    return HealthAlertModel(
      id: id,
      caregiverId: caregiverId,
      patientId: patientId,
      type: type,
      title: title,
      message: message,
      severity: severity,
      source: source,
      isRead: false,
      createdAt: createdAt,
    );
  }

  DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Stream<R> _combineLatest3<A, B, C, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    R Function(A a, B b, C c) combiner,
  ) {
    late A latestA;
    late B latestB;
    late C latestC;

    var hasA = false;
    var hasB = false;
    var hasC = false;

    final controller = StreamController<R>();

    void emitIfReady() {
      if (hasA && hasB && hasC && !controller.isClosed) {
        controller.add(combiner(latestA, latestB, latestC));
      }
    }

    late StreamSubscription subA;
    late StreamSubscription subB;
    late StreamSubscription subC;

    subA = streamA.listen(
      (value) {
        latestA = value;
        hasA = true;
        emitIfReady();
      },
      onError: controller.addError,
    );

    subB = streamB.listen(
      (value) {
        latestB = value;
        hasB = true;
        emitIfReady();
      },
      onError: controller.addError,
    );

    subC = streamC.listen(
      (value) {
        latestC = value;
        hasC = true;
        emitIfReady();
      },
      onError: controller.addError,
    );

    controller.onCancel = () {
      subA.cancel();
      subB.cancel();
      subC.cancel();
    };

    return controller.stream;
  }
}