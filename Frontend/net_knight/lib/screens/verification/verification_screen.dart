import 'package:flutter/material.dart';
import 'widgets/otp_fields.dart';
import 'services/verification_service.dart';
import 'package:dio/dio.dart';

const _kPrimary = Color(0xff0077c0);
const _kDark = Color(0xff1d242b);

class VerificationArgs {
  final String email;
  final bool isFromLogin;

  const VerificationArgs({
    required this.email,
    this.isFromLogin = false,
  });
}

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key, required this.args});

  final VerificationArgs args;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _otpFieldsKey = GlobalKey<OtpFieldsState>();
  final _service = VerificationService();
  bool _isLoading = false;
  bool _verifyCalledOnce = false;

  String get _maskedEmail {
    final parts = widget.args.email.split('@');
    if (parts.length != 2) return widget.args.email;
    final name = parts[0];
    final masked = name.length <= 2 ? '$name***' : '${name.substring(0, 2)}***';
    return '$masked@${parts[1]}';
  }

  Future<void> _verify() async {
    if (_verifyCalledOnce) return;

    final otp = _otpFieldsKey.currentState?.otp ?? '';
    if (otp.length < 6) {
      _showError('Please enter the complete verification code');
      return;
    }

    _verifyCalledOnce = true;
    setState(() => _isLoading = true);

    try {
      bool saved = false;

      if (widget.args.isFromLogin) {
        saved = await _service.verifyLogin(widget.args.email, otp);
      } else {
        saved = await _service.verifyEmail(widget.args.email, otp);
      }

      if (!mounted) return;

      if (saved) {
        // ← token اتحفظ → روح للـ dashboard
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/dashboard',
          (route) => false,
        );
      } else {
        // ← مفيش token في الـ response
        _verifyCalledOnce = false;
        _showError('Verification failed. Please try again.');
        _otpFieldsKey.currentState?.clear();
      }
    } on DioException catch (e) {
      _verifyCalledOnce = false;
      final msg = e.response?.statusCode == 400
          ? 'Invalid or expired code'
          : 'Connection error. Please try again.';
      _showError(msg);
      _otpFieldsKey.currentState?.clear();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await _service.resendCode(widget.args.email);
      if (mounted) {
        _verifyCalledOnce = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code resent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (_) {
      _showError('Failed to resend code. Please try again.');
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  icon: const Icon(Icons.reply_outlined, color: _kDark),
                  label: const Text(
                    'Back to log in',
                    style: TextStyle(color: _kDark),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const CircleAvatar(
                radius: 28,
                backgroundColor: _kDark,
                child: Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Verification Code',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _kDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'A verification code has been sent to:\n$_maskedEmail',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              OtpFields(key: _otpFieldsKey),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resend,
                child: const Text(
                  'Resend Code?',
                  style: TextStyle(color: _kPrimary),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    disabledBackgroundColor: _kPrimary.withOpacity(0.5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Verify'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
