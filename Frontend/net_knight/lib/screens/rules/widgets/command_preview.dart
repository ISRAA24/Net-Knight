import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kTerminalBg = Color(0xFF1E252B);

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
      duration: const Duration(milliseconds: 300),
      child: isSuccess ? _SuccessMessage() : _CommandBox(command: command),
    );
  }
}

class _SuccessMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('success'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 22),
        const SizedBox(width: 8),
        Text(
          'Rule added successfully',
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
  const _CommandBox({required this.command});
  final String command;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('command'),
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
                color: Color(0xff22C55E), fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              command,
              style:
                  GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
