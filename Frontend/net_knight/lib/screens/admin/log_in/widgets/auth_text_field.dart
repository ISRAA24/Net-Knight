import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    required this.validator,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final FormFieldValidator<String> validator;
  final bool obscureText;
  final Widget? suffixIcon;

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(prefixIcon, color: Colors.white60),
        suffixIcon: suffixIcon,
        border: _border(Color(0xfffafafa).withOpacity(0.6)),
        enabledBorder: _border(Color(0xfffafafa).withOpacity(0.6)),
        focusedBorder: _border(const Color(0xff0077c0)),
        errorStyle: const TextStyle(color: Color(0xffef4444)),
      ),
    );
  }
}
