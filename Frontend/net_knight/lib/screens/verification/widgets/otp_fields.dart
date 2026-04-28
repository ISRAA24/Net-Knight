import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'otp_box.dart';

const _kOtpLength = 6;

class OtpFields extends StatefulWidget {
  const OtpFields({super.key});

  @override
  State<OtpFields> createState() => OtpFieldsState();
}

class OtpFieldsState extends State<OtpFields> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_kOtpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_kOtpLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < _kOtpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  KeyEventResult _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String get otp => _controllers.map((c) => c.text).join();

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _kOtpLength,
        (index) => OtpBox(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          onChanged: (value) => _onChanged(value, index),
          onKeyEvent: (event) => _onKeyEvent(event, index),
        ),
      ),
    );
  }
}
