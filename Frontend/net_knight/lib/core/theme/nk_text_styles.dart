import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nk_colors.dart';

class NKTextStyles {
  NKTextStyles._();

  static TextStyle get heading => GoogleFonts.rajdhani(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: NKColors.onSurface,
      );

  static TextStyle get subheading =>
      GoogleFonts.rajdhani(fontSize: 13, color: Colors.black54);

  static TextStyle get sidebarLabel =>
      GoogleFonts.rajdhani(fontSize: 13, color: const Color(0xFFE1DBDB));

  static TextStyle get sidebarSection =>
      const TextStyle(color: Color(0xFF8BA8A8), fontSize: 10, letterSpacing: 2);

  static TextStyle get mono => GoogleFonts.jetBrainsMono(fontSize: 12);
}
