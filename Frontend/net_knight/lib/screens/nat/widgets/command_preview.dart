import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    if (isSuccess) {
      return Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 22),
            const SizedBox(width: 8),
            Text(
              'Rule Added successfully',
              style: GoogleFonts.rajdhani(
                fontSize: 17,
                color: const Color(0xFF22C55E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // لو command فاضي → متعرضش حاجة
    if (command.isEmpty) return const SizedBox.shrink();

    // لو في command → اعرضه
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xff1d242b),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text(r'$ ',
              style: TextStyle(
                  color: Color(0xff22C55E), fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
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
