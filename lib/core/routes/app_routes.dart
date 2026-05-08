class AppRoutes {
  AppRoutes._();

  static const String welcome         = '/welcome';
  static const String roleSelection   = '/role-selection';
  static const String login           = '/login';

  // Caregiver
  static const String caregiverHome   = '/caregiver/home';
  static const String medications     = '/caregiver/medications';
  static const String addMedication   = '/caregiver/add-medication';
  static const String appointments    = '/caregiver/appointments';
  static const String careNotes       = '/caregiver/care-notes';
  static const String addCareNote     = '/caregiver/add-note';

  // Family
  static const String familyHome        = '/family/home';
  static const String familyMedications = '/family/medications';

  // Shared
  static const String notifications   = '/notifications';
  static const String reports         = '/reports';
  static const String aiAssistant     = '/ai-assistant';
}