import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/interface_model.dart';
import '../../../../core/theme/nk_colors.dart';

class EditInterfaceDialog extends StatefulWidget {
  const EditInterfaceDialog({
    super.key,
    required this.item,
    required this.onSave,
  });

  final InterfaceModel item;
  final void Function(InterfaceModel updated) onSave;

  @override
  State<EditInterfaceDialog> createState() => _EditInterfaceDialogState();
}

class _EditInterfaceDialogState extends State<EditInterfaceDialog> {
  late final TextEditingController _logicalNameCtrl;
  late final TextEditingController _ipCtrl;
  late String _status;

  @override
  void initState() {
    super.initState();
    _logicalNameCtrl =
        TextEditingController(text: widget.item.logicalName);
    _ipCtrl = TextEditingController(text: widget.item.ip);
    _status = widget.item.status;
  }

  @override
  void dispose() {
    _logicalNameCtrl.dispose();
    _ipCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(
      widget.item.copyWith(
        logicalName: _logicalNameCtrl.text.trim(),
        status: _status,
        ip: _ipCtrl.text.trim(),
      ),
    );
    Navigator.pop(context);
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: NKColors.blue, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Header ───────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  _HeaderBtn(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit Interface',
                      style: GoogleFonts.rajdhani(
                          fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                  ),
                  _HeaderBtn(
                    icon: Icons.check,
                    onTap: _save,
                  ),
                ],
              ),
            ),

            // ─── Body ─────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Real Name (read-only)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Real Name',
                            style: TextStyle(
                                fontSize: 12, color: Colors.black45)),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.realName,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Logical Name (editable)
                  TextField(
                    controller: _logicalNameCtrl,
                    decoration: _dec('Logical Name'),
                  ),
                  const SizedBox(height: 14),

                  // IP Address (editable)
                  TextField(
                    controller: _ipCtrl,
                    decoration: _dec('IP Address'),
                  ),
                  const SizedBox(height: 14),

                  // Status
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: _dec('Status'),
                    items: const [
                      DropdownMenuItem(
                          value: 'connected',
                          child: Text('Connected')),
                      DropdownMenuItem(
                          value: 'disconnected',
                          child: Text('Disconnected')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header Button ────────────────────────────────────────

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }
}