import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kTerminalBg = Color(0xff1d242b);

class CommandPreview extends StatelessWidget {
  const CommandPreview({
    super.key,
    required this.command,
    required this.isSuccess,
  });

  final String command;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: isSuccess
          ? _SuccessMessage(key: const ValueKey('success'))
          : _CommandBox(key: ValueKey(command), command: command),
    );
  }
}

class _SuccessMessage extends StatelessWidget {
  const _SuccessMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 22),
        const SizedBox(width: 8),
        Text(
          'Chain added successfully',
          style: GoogleFonts.rajdhani(
            color: const Color(0xFF22C55E),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _CommandBox extends StatelessWidget {
  const _CommandBox({super.key, required this.command});
  final String command;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: _kTerminalBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text(
            r'$ ',
            style: TextStyle(
                color: Color(0xff22c55e), fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              command,
              style: GoogleFonts.jetBrainsMono(
                  color: Color(0xfffafafa), fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
