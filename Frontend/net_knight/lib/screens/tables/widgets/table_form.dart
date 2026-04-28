import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/nk_colors.dart';

class TableForm extends StatelessWidget {
  const TableForm({
    super.key,
    required this.nameController,
    required this.selectedFamily,
    required this.onFamilyChanged,
    required this.onNameChanged,
  });

  final TextEditingController nameController;
  final String selectedFamily;
  final ValueChanged<String> onFamilyChanged;
  final ValueChanged<String> onNameChanged;

  static const _families = ['ip', 'inet', 'bridge', 'netdev', 'arp'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Table Name ───────────────────────────────────
        _FieldLabel(label: 'Table name'),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextField(
            controller: nameController,
            onChanged: onNameChanged,
            decoration: InputDecoration(
              hintText: 'table name',
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF93C5FD)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: NKColors.primary, width: 1.5),
              ),
            ),
          ),
        ),

        const SizedBox(height: 35),

        // ─── Family ───────────────────────────────────────
        _FieldLabel(label: 'Family'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF93C5FD)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedFamily,
              isExpanded: true,
              items: _families
                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                  .toList(),
              onChanged: (val) {
                if (val != null) onFamilyChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Field Label ──────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.rajdhani(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1D242B),
      ),
    );
  }
}
