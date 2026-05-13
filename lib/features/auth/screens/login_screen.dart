//UI screen with login fields
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus(); // hide the keyboard
    if (!_formKey.currentState!.validate()) {
      return; // stop if fields are invalid
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.signIn(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return; // check if widget is still in the tree

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      //TODO: navigate to home screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //-------------header, logo, title
              const SizedBox(height: 56),
              Center(child: Text('CareConnect', style: AppTextStyles.h1)),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Sign in to continue',
                  style: AppTextStyles.secondary,
                ),
              ),
              const SizedBox(height: 40),

              const SizedBox(height: 40),
              //-------------form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Email',
                      hint: 'you@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Password',
                      hint: 'Enter your password',
                      controller: _passwordController,
                      isPassword: true,
                      validator: Validators.password,
                    ),
                  ],
                ),
              ),

              //-------------error message (only shows if not null)
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.destructive,
                  ),
                ),
              ],

              //-------------login button
              const SizedBox(height: 24),
              CustomButton(
                label: "Sign in",
                onPressed: _handleLogin,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
