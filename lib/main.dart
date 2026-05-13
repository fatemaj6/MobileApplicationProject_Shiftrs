import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CareConnectApp());
}

class CareConnectApp extends StatelessWidget {
  const CareConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(
          child: Text('CareConnect'),
        ), //default home -> LoginScreen(),
      ),
    );
  }
}
