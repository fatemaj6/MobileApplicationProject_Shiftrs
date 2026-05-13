import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/home/screens/home_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.welcome:       (ctx) => const WelcomeScreen(),
  AppRoutes.roleSelection: (ctx) => const RoleSelectionScreen(),
  AppRoutes.register:      (ctx) => const RegisterScreen(),
  AppRoutes.login:         (ctx) => const Scaffold(
    body: Center(child: Text('Login — Coming Next')),
  ),
  AppRoutes.caregiverHome: (ctx) => const HomeScreen(),
  AppRoutes.profile:       (ctx) => const ProfileScreen(),
};