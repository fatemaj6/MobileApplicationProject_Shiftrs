import '../../appointments/models/appointment_model.dart';
import '../../../data/model/medication_model.dart';

/// Aggregated data model for a care summary report.
/// Composed only from existing [AppointmentModel] and [MedicationModel] data.
class CareReportModel {
  final DateTime startDate;
  final DateTime endDate;
  final String generatedBy; 
  final String selectedCategory;// caregiverId

  // Appointments
  final List<AppointmentModel> appointments;

  // Medications
  final List<MedicationModel> medications;

  // Derived stats (computed in constructor)
  late final int totalAppointments;
  late final int upcomingAppointments;
  late final int pastAppointments;
  late final int cancelledAppointments;

  late final int totalMedications;
  late final int givenMedications;
  late final int missedMedications;
  late final int pendingMedications;
  late final double adherencePercentage;

  CareReportModel({
  required this.startDate,
  required this.endDate,
  required this.generatedBy,
  required this.selectedCategory,
  required this.appointments,
  required this.medications,
}) {
    // Appointment stats
    totalAppointments = appointments.length;
    upcomingAppointments =
        appointments.where((a) => a.status == 'upcoming').length;
    pastAppointments =
        appointments.where((a) => a.isPast && a.status != 'cancelled').length;
    cancelledAppointments =
        appointments.where((a) => a.status == 'cancelled').length;

    // Medication stats
    totalMedications = medications.length;
    givenMedications = medications.where((m) => m.status == 'given').length;
    missedMedications = medications.where((m) => m.status == 'missed').length;
    pendingMedications = medications.where((m) => m.status == 'pending').length;
    adherencePercentage = totalMedications == 0
        ? 0
        : (givenMedications / totalMedications * 100);
  }

  bool get isEmpty => appointments.isEmpty && medications.isEmpty;
}
