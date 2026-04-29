import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupFormPanel extends StatefulWidget {
  const SignupFormPanel({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onToggleConfirmObscure,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleConfirmObscure;
  final VoidCallback onSubmit;

  @override
  State<SignupFormPanel> createState() => _SignupFormPanelState();
}

class _SignupFormPanelState extends State<SignupFormPanel> {
  bool _agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xff1d242b),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Center(
              child: Text(
                'Sign Up',
                style:
                    GoogleFonts.aDLaMDisplay(fontSize: 26, color: Colors.white),
              ),
            ),
            const Gap(16),

            // Username
            _FieldLabel(label: 'User Name', icon: Icons.person_outline),
            const Gap(4),
            _CompactTextField(
              controller: widget.usernameController,
              hint: 'Enter user name',
              prefixIcon: Icons.person_outline,
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Please enter your username'
                  : null,
            ),
            const Gap(10),

            // Email
            _FieldLabel(label: 'Email', icon: Icons.email_outlined),
            const Gap(4),
            _CompactTextField(
              controller: widget.emailController,
              hint: 'Enter email',
              prefixIcon: Icons.email_outlined,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your email';
                if (!v.contains('@')) return 'Please enter a valid email';
                return null;
              },
            ),
            const Gap(10),

            // Password
            _FieldLabel(label: 'Password', icon: Icons.lock_outline),
            const Gap(4),
            _CompactTextField(
              controller: widget.passwordController,
              hint: 'Enter password',
              prefixIcon: Icons.lock_outline,
              obscureText: widget.obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  widget.obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.white60,
                  size: 18,
                ),
                onPressed: widget.onToggleObscure,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your password';
                if (v.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const Gap(10),

            // Confirm Password
            _FieldLabel(label: 'Confirm Password', icon: Icons.lock_outline),
            const Gap(4),
            _CompactTextField(
              controller: widget.confirmPasswordController,
              hint: 'Confirm password',
              prefixIcon: Icons.lock_outline,
              obscureText: widget.obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  widget.obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.white60,
                  size: 18,
                ),
                onPressed: widget.onToggleConfirmObscure,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Please confirm your password';
                }
                if (v != widget.passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const Gap(10),

            // Terms Checkbox
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreedToTerms,
                    onChanged: (v) =>
                        setState(() => _agreedToTerms = v ?? false),
                    activeColor: const Color(0xff0077c0),
                    side: const BorderSide(color: Colors.white38),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.white60),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'terms of service',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xff0077c0),
                              decoration: TextDecoration.underline),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'privacy policy',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xff0077c0),
                              decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Gap(12),

            // Sign Up Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: widget.isLoading
                    ? null
                    : () {
                        if (!_agreedToTerms) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Please agree to the terms of service'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        widget.onSubmit();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0077c0),
                  disabledBackgroundColor:
                      const Color(0xff0077c0).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: widget.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Sign Up',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
            const Gap(10),

            // Note
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'note: ',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xff0077c0),
                        fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'this is the first account for the system, so it will be a super admin account by default',
                    style:
                        GoogleFonts.inter(fontSize: 11, color: Colors.white60),
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

// ─── Compact TextField ────────────────────────────────────────────────────────

class _CompactTextField extends StatelessWidget {
  const _CompactTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.validator,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final FormFieldValidator<String> validator;
  final bool obscureText;
  final Widget? suffixIcon;

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: Colors.white60, size: 18),
        suffixIcon: suffixIcon,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: _border(Colors.white24),
        enabledBorder: _border(Colors.white24),
        focusedBorder: _border(const Color(0xff0077c0)),
        errorBorder: _border(Colors.redAccent),
        focusedErrorBorder: _border(Colors.redAccent),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
      ),
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 14),
        const Gap(5),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}
