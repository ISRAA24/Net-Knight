import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kRoles = ['Admin', 'Analyst'];
const _kBlue = Color(0xFF3B82F6);
const _kDark = Color(0xFF1D242B);

class UserDialog extends StatefulWidget {
  const UserDialog({
    super.key,
    required this.onSave,
    this.isEditing = false,
    this.initialName,
    this.initialEmail,
    this.initialRole,
    this.isLoading = false,
  });

  final Future<void> Function(
      String name, String email, String password, String role) onSave;
  final bool isEditing;
  final String? initialName;
  final String? initialEmail;
  final String? initialRole;
  final bool isLoading;

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late String _role;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName ?? '');
    _email = TextEditingController(text: widget.initialEmail ?? '');
    _password = TextEditingController();
    _role = _kRoles.contains(widget.initialRole)
        ? widget.initialRole!
        : _kRoles.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // ← استنى الـ API call تخلص الأول
      await widget.onSave(
        _name.text.trim(),
        _email.text.trim(),
        _password.text,
        _role,
      );
      // ← بعد ما تخلص بنجاح اقفل الـ dialog
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isEditing ? 'Edit User' : 'Add New User',
                    style: GoogleFonts.rajdhani(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Fields ───────────────────────────
              _NKField(hint: 'Username', controller: _name),
              const SizedBox(height: 15),
              _NKField(hint: 'Email', controller: _email),
              const SizedBox(height: 15),
              _NKField(
                hint: 'Password',
                controller: _password,
                isPassword: true,
                obscure: _obscurePassword,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 15),
              _NKDropdown(
                value: _role,
                items: _kRoles,
                onChanged: (v) => setState(() => _role = v),
              ),
              const SizedBox(height: 25),

              // ─── Save Button ──────────────────────
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton.small(
                  onPressed: _isLoading ? null : _submit,
                  backgroundColor: _kDark,
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(
                          widget.isEditing ? Icons.check : Icons.add,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── NKField ──────────────────────────────────────────────

class _NKField extends StatelessWidget {
  const _NKField({
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.obscure = false,
    this.onToggleObscure,
  });

  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword && obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: Colors.grey,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBlue, width: 2),
        ),
      ),
    );
  }
}

// ─── NKDropdown ───────────────────────────────────────────

class _NKDropdown extends StatelessWidget {
  const _NKDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black, fontSize: 15),
          items: items
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(v, style: const TextStyle(color: Colors.black)),
                  ))
              .toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }
}
