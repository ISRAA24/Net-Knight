import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff0077c0),
          disabledBackgroundColor: const Color(0xff0077c0).withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Color(0xfffafafa), strokeWidth: 2),
              )
            : Text(
                'Sign In',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xfffafafa)),
              ),
      ),
    );
  }
}
