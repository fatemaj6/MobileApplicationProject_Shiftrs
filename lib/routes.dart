import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';

import 'features/auth/screens/welcome_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';

import 'features/profile/screens/profile_screen.dart';
import 'features/home/screens/home_screen.dart';

// Medication screens
import 'features/medication/screens/medication_list_screen.dart';
import 'features/medication/screens/family_medication_schedule_screen.dart';

// Appointment screens
import 'features/appointments/screens/appointment_list_screen.dart';
import 'features/appointments/screens/add_appointment_screen.dart';
import 'features/appointments/screens/edit_appointment_screen.dart';
import 'features/appointments/models/appointment_model.dart';
import 'features/appointments/screens/family_appointment_list_screen.dart';
import 'features/notifications/screens/appointment_notifications_screen.dart';
import 'features/care_reports/screens/care_report_screen.dart'; // SMAP-34

// Care Note screens
import 'features/care_notes/screens/care_note_list_screen.dart';
import 'features/care_notes/screens/add_care_note_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  // Auth routes
  AppRoutes.welcome: (ctx) => const WelcomeScreen(),
  AppRoutes.roleSelection: (ctx) => const RoleSelectionScreen(),
  AppRoutes.register: (ctx) => const RegisterScreen(),
  AppRoutes.login: (ctx) => const LoginScreen(),
  AppRoutes.resetPassword: (ctx) => const ResetPasswordScreen(),

  // Home routes
  AppRoutes.caregiverHome: (ctx) => const HomeScreen(),
  AppRoutes.familyHome: (ctx) => const HomeScreen(),

  // Shared routes
  AppRoutes.profile: (ctx) => const ProfileScreen(),

  // Medication routes
  AppRoutes.medications: (ctx) => const MedicationListScreen(),
  AppRoutes.familyMedications: (ctx) => const FamilyMedicationScheduleScreen(),

  // Appointment routes
  AppRoutes.appointments: (ctx) => const AppointmentListScreen(),
  AppRoutes.addAppointment: (ctx) {
    final args = ModalRoute.of(ctx)?.settings.arguments as String?;
    return AddAppointmentScreen(caregiverId: args ?? '');
  },
  AppRoutes.editAppointment: (ctx) {
    final appointment =
        ModalRoute.of(ctx)!.settings.arguments as AppointmentModel;
    return EditAppointmentScreen(appointment: appointment);
  },
  AppRoutes.familyAppointments: (ctx) => const FamilyAppointmentListScreen(),
  AppRoutes.familyNotifications: (ctx) =>
      const AppointmentNotificationsScreen(),

  // Care Note routes
  AppRoutes.careNotes: (ctx) => const CareNoteListScreen(),
  AppRoutes.addCareNote: (ctx) => const AddCareNoteScreen(),
  AppRoutes.familyCareNotes: (ctx) {
    final caregiverId = ModalRoute.of(ctx)?.settings.arguments as String?;
    return CareNoteListScreen(
      isFamilyView: true,
      caregiverIdOverride: caregiverId,
    );
  },

  // SMAP-34: Care Summary Report
  AppRoutes.careReport: (ctx) => const CareReportScreen(),
};