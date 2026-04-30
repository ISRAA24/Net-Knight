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
    // لو success → رسالة النجاح
    if (isSuccess) return const _SuccessMessage();

    // لو command فاضي → متعرضش حاجة
    if (command.isEmpty) return const SizedBox.shrink();

    // لو في command → اعرضه
    return _CommandBox(command: command);
  }
}

// ─── Success ──────────────────────────────────────────────

class _SuccessMessage extends StatelessWidget {
  const _SuccessMessage();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 22),
        const SizedBox(width: 8),
        Text(
          'Table added successfully',
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
            style: TextStyle(
                color: Color(0xff22c55e), fontWeight: FontWeight.bold),
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
