import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'data/repositories/profile_repository.dart';
import 'features/medication/controllers/medication_controller.dart';
import 'routes.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<ProfileRepository>(
          create: (_) => ProfileRepository(),
        ),
        ChangeNotifierProvider<MedicationController>(
          create: (_) => MedicationController(),
        ),
      ],
      child: const CareConnectApp(),
    ),
  );
}

class CareConnectApp extends StatelessWidget {
  const CareConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // App opens from welcome / role selection flow
      initialRoute: AppRoutes.welcome,
      routes: appRoutes,
    );
  }
}