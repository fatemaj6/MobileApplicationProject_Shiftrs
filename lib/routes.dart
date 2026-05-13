import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
// Medication screens
import 'features/medication/screens/medication_list_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.welcome:       (ctx) => const WelcomeScreen(),
  AppRoutes.roleSelection: (ctx) => const RoleSelectionScreen(),
  AppRoutes.register:      (ctx) => const RegisterScreen(),
  AppRoutes.login:         (ctx) => const LoginScreen(),
  AppRoutes.caregiverHome: (ctx) => const HomeScreen(),
  AppRoutes.familyHome:    (ctx) => const HomeScreen(),
  AppRoutes.profile:       (ctx) => const ProfileScreen(),
  AppRoutes.resetPassword: (context) => const ResetPasswordScreen(),

  // Medication routes
  AppRoutes.medications:   (ctx) => const MedicationListScreen(),
  AppRoutes.familyMedications:  (ctx) => const MedicationListScreen(),
};