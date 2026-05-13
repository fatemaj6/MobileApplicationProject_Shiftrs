import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.caregiverHome),
          child: const Text('Go to Home Screen'),
        ),
      ),
    );
  }
}
