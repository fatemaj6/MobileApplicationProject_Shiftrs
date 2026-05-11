import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late String _role;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _role = ModalRoute.of(context)?.settings.arguments as String? ?? 'caregiver';
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Firebase registration will go here in next step
    await Future.delayed(const Duration(seconds: 1)); // placeholder

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCaregiver = _role == 'caregiver';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cyanBg, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    label: const Text(
                      'Back',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isCaregiver
                          ? [AppColors.primary, AppColors.primaryLight]
                          : [AppColors.purple, AppColors.purpleLight],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Create Account',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up as ${isCaregiver ? 'Caregiver' : 'Family Member'}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Full Name',
                        hint: 'e.g. Siti Nurhaliza',
                        controller: _nameController,
                        prefixIcon: Icons.person_outline,
                        validator: (v) => Validators.required(v, 'Full name'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Email',
                        hint: 'your.email@example.com',
                        controller: _emailController,
                        prefixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _passwordController,
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Confirm Password',
                        hint: '••••••••',
                        controller: _confirmPasswordController,
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please confirm your password.';
                          }
                          if (v != _passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.missedBg,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.missed,
                              fontSize: 14,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Register button
                      CustomButton(
                        label: 'Create Account',
                        onPressed: _handleRegister,
                        isLoading: _isLoading,
                        backgroundColor: isCaregiver
                            ? AppColors.primary
                            : AppColors.purple,
                      ),
                      const SizedBox(height: 16),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: isCaregiver
                                    ? AppColors.primary
                                    : AppColors.purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
