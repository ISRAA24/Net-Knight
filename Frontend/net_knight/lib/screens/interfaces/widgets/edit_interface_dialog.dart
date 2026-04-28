import 'package:flutter/material.dart';
import '../models/interface_model.dart';

const _kBlue = Color(0xFF3B82F6);
const _kConnected = Color(0xFF22C55E);
const _kDisconnected = Color(0xFFEF4444);
const _kDark = Color(0xFF1D242B);
const _kStatusOptions = ['connected', 'disconnected'];

class EditInterfaceDialog extends StatefulWidget {
  const EditInterfaceDialog({
    super.key,
    required this.item,
    required this.onSave,
  });

  final InterfaceModel item;
  final ValueChanged<InterfaceModel> onSave;

  @override
  State<EditInterfaceDialog> createState() => _EditInterfaceDialogState();
}

class _EditInterfaceDialogState extends State<EditInterfaceDialog> {
  late final TextEditingController _logicalNameCtrl;
  late final TextEditingController _ipCtrl;
  late String _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _logicalNameCtrl = TextEditingController(text: widget.item.logicalName);
    _ipCtrl = TextEditingController(text: widget.item.ip);
    _status = _kStatusOptions.contains(widget.item.status)
        ? widget.item.status
        : _kStatusOptions.first;
  }

  @override
  void dispose() {
    _logicalNameCtrl.dispose();
    _ipCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _isLoading = true);
    widget.onSave(
      widget.item.copyWith(
        logicalName: _logicalNameCtrl.text.trim(),
        status: _status,
        ip: _ipCtrl.text.trim(),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Interface',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Logical Name ─────────────────────
              _NKTextField(label: 'Logical Name', controller: _logicalNameCtrl),
              const SizedBox(height: 15),

              // ─── Real Name (read only) ────────────
              _NKTextField(
                label: 'Real Interface Name',
                controller: TextEditingController(text: widget.item.realName),
                readOnly: true,
              ),
              const SizedBox(height: 15),

              // ─── Status ───────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _status,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    items: _kStatusOptions.map((status) {
                      final color =
                          status == 'connected' ? _kConnected : _kDisconnected;
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status, style: TextStyle(color: color)),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // ─── IP ───────────────────────────────
              _NKTextField(label: 'IP Address', controller: _ipCtrl),
              const SizedBox(height: 25),

              // ─── Save Button ──────────────────────
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: _isLoading ? null : _submit,
                  backgroundColor: _kDark,
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NKTextField extends StatelessWidget {
  const _NKTextField({
    required this.label,
    required this.controller,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: readOnly ? const TextStyle(fontWeight: FontWeight.w600) : null,
      decoration: InputDecoration(
        labelText: label,
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[100] : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBlue, width: 2),
        ),
      ),
    );
  }
}
