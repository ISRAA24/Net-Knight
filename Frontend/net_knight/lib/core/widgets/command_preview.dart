import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kTerminalBg = Color(0xFF1E252B);
const _kGreen = Color(0xFF22C55E);
class CommandPreview extends StatelessWidget {
  const CommandPreview({
    super.key,
    required this.command,
    required this.isSuccess,
    this.successMessage = 'Added successfully',
  });

  final String command;
  final bool isSuccess;
  final String successMessage;

  @override
  Widget build(BuildContext context) {
    if (isSuccess) return _SuccessMessage(message: successMessage);

    if (command.isEmpty) return const SizedBox.shrink();

    return _CommandBox(command: command);
  }
}

// ─── Success Message ──────────────────────────────────────

class _SuccessMessage extends StatelessWidget {
  const _SuccessMessage({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: _kGreen, size: 22),
        const SizedBox(width: 8),
        Text(
          message,
          style: GoogleFonts.rajdhani(
            color: _kGreen,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

// ─── Command Box ──────────────────────────────────────────

class _CommandBox extends StatelessWidget {
  const _CommandBox({required this.command});
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
            style: TextStyle(color: _kGreen, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              command,
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xfffafafa),
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
