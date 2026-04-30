import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/signup_form_panel.dart';
import 'services/signup_service.dart';
import '../verification/verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _signupService = SignupService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _signupService.signup(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(
          context,
          '/verification',
          arguments: VerificationArgs(
            email: _emailController.text.trim(),
            isFromLogin: false, // ← جاي من signup
          ),
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 409
          ? 'Account already exists'
          : 'Connection error. Please try again.';
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
            Expanded(
              child: SignupFormPanel(
                formKey: _formKey,
                usernameController: _usernameController,
                emailController: _emailController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                obscurePassword: _obscurePassword,
                obscureConfirmPassword: _obscureConfirmPassword,
                isLoading: _isLoading,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onToggleConfirmObscure: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
                onSubmit: _signup,
              ),
            ),
            const Gap(50),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/Logo.png', height: 120),
                  const Gap(16),
                  Text(
                    'NetKnight',
                    style: GoogleFonts.aDLaMDisplay(
                        fontSize: 32, color: const Color(0xff0077c0)),
                  ),
                  const Gap(8),
                  Text(
                    'CREATE AN ACCOUNT',
                    style: GoogleFonts.aDLaMDisplay(
                        fontSize: 22, color: const Color(0xff1d242b)),
                  ),
                  const Gap(8),
                  Text(
                    'Join our platform. Get started by creating\nyour account to monitor network security.',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xff0077c0),
                        fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
