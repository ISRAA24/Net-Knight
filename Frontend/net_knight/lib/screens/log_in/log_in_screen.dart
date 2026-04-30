import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'widgets/branding_panel.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/submit_button.dart';
import 'services/auth_service.dart';
import '../verification/verification_screen.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/verification',
          arguments: VerificationArgs(
            email: response.email,
            isFromLogin: true,
          ),
        );
      }
    } on DioException catch (e) {
      final message = e.response?.statusCode == 401
          ? 'Invalid username or password'
          : 'Connection error. Please try again.';
      _showError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message), backgroundColor: const Color(0xffef4444)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffafafa),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Expanded(child: BrandingPanel()),
            const Gap(50),
            Expanded(
              child: _LoginFormPanel(
                formKey: _formKey,
                usernameController: _usernameController,
                passwordController: _passwordController,
                obscurePassword: _obscurePassword,
                isLoading: _isLoading,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onSubmit: _login,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xff1d242b),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sign In',
              style: TextStyle(
                  fontSize: 32,
                  color: Color(0xfffafafa),
                  fontWeight: FontWeight.bold),
            ),
            const Gap(32),
            AuthTextField(
              controller: usernameController,
              label: 'Username',
              prefixIcon: Icons.person_outline,
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Please enter your username'
                  : null,
            ),
            const Gap(16),
            AuthTextField(
              controller: passwordController,
              label: 'Password',
              prefixIcon: Icons.lock_outline,
              obscureText: obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xfffafafa).withOpacity(0.6),
                ),
                onPressed: onToggleObscure,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your password';
                if (v.length < 6)
                  return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const Gap(24),
            SubmitButton(isLoading: isLoading, onPressed: onSubmit),
          ],
        ),
      ),
    );
  }
}
