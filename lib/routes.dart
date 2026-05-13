import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/auth/screens/welcome_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.profile: (context) => const ProfileScreen(),
  AppRoutes.caregiverHome: (context) => const HomeScreen(),
  AppRoutes.welcome: (context) => const WelcomeScreen(),
};
