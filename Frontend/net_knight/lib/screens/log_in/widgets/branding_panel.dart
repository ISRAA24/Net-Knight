import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandingPanel extends StatelessWidget {
  const BrandingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/Logo.png', height: 100),
        const Gap(12),
        Text(
          'NetKnight',
          style: GoogleFonts.aDLaMDisplay(
              fontSize: 32, color: const Color(0xff0077c0)),
        ),
        Text(
          'WELCOME BACK',
          style: GoogleFonts.aDLaMDisplay(
              fontSize: 24, color: const Color(0xff1d242b)),
        ),
        const Gap(8),
        Text(
          'Please enter your credentials to access the security management console.',
          style:
              GoogleFonts.inter(fontSize: 14, color: const Color(0xff1d242b)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
