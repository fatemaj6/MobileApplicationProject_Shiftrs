import 'package:flutter/material.dart';

import '../../../data/services/auth_service.dart';

class ResetPasswordController extends ChangeNotifier {
  ResetPasswordController({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  final emailController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  Future<void> sendResetLink() async {
    final email = emailController.text.trim();

    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    final error = await _authService.resetPassword(email);

    isLoading = false;

    if (error != null) {
      errorMessage = error;
      successMessage = null;
    } else {
      errorMessage = null;
      successMessage = 'Password reset link sent. Please check your email.';
    }

    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}