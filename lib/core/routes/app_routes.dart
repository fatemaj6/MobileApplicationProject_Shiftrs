class AppRoutes {
  AppRoutes._();

  // Onboarding
  static const String welcome = '/welcome';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String register = '/register';
  static const String resetPassword = '/reset-password';

  // Caregiver
  static const String caregiverHome = '/caregiver/home';
  static const String medications = '/caregiver/medications';
  static const String addMedication = '/caregiver/add-medication';
  static const String editMedication = '/caregiver/edit-medication';
  static const String appointments = '/caregiver/appointments';
  static const String careNotes = '/caregiver/care-notes';
  static const String addCareNote = '/caregiver/add-note';
  static const String healthTrends = '/caregiver/health-trends';

  // Family
  static const String familyHome = '/family/home';
  static const String familyMedications = '/family/medications';
  static const String familyAppointments = '/family/appointments';
  static const String familyNotifications = '/family/notifications';
  static const String familyCareNotes = '/family/care-notes';
  static const String familyHealthAlerts = '/family/health-alerts';

  // Shared
  static const String notifications = '/notifications';
  static const String reports = '/reports';
  static const String careReport = '/reports/care-summary'; // SMAP-34
  static const String aiAssistant = '/ai-assistant';
  static const String profile = '/profile';

  // Appointment routes
  static const String addAppointment = '/appointments/add';
  static const String editAppointment = '/appointments/edit';

  //Caregiver health alerts
  static const String healthAlerts = '/caregiver/health-alerts';
}
