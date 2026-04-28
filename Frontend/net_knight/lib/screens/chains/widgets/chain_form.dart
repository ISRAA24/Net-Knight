import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBlue = Color(0xFF3B82F6);
const _kBorder = Color(0xFF93C5FD);

class ChainForm extends StatelessWidget {
  const ChainForm({
    super.key,
    required this.tables,
    required this.selectedTableName,
    required this.chainNameController,
    required this.priorityController,
    required this.selectedHook,
    required this.selectedPolicy,
    required this.selectedType,
    required this.priorityValue,
    required this.onTableChanged,
    required this.onHookChanged,
    required this.onPolicyChanged,
    required this.onTypeChanged,
    required this.onPriorityUp,
    required this.onPriorityDown,
    required this.onChanged,
  });

  final List<String> tables;
  final String selectedTableName;
  final TextEditingController chainNameController;
  final TextEditingController priorityController;
  final String selectedHook;
  final String selectedPolicy;
  final String selectedType;
  final int priorityValue;
  final ValueChanged<String> onTableChanged;
  final ValueChanged<String> onHookChanged;
  final ValueChanged<String> onPolicyChanged;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onPriorityUp;
  final VoidCallback onPriorityDown;
  final VoidCallback onChanged;

  static const _hooks = [
    'prerouting',
    'postrouting',
    'forward',
    'input',
    'output'
  ];
  static const _policies = ['accept', 'deny'];
  static const _types = ['route', 'filter', 'nat'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 40,
      runSpacing: 30,
      children: [
        // ─── Table Name ──────
        _FieldWrapper(
          label: 'Table name',
          child: tables.isEmpty
              ? const _LoadingField()
              : _buildDropdown(tables, selectedTableName, onTableChanged),
        ),

        // ─── Hook ─────────────────────────────────────
        _FieldWrapper(
          label: 'Hook',
          child: _buildDropdown(_hooks, selectedHook, onHookChanged),
        ),

        // ─── Chain Name ───────────────────────────────
        _FieldWrapper(
          label: 'Chain name',
          child: _buildTextField(chainNameController, 'chain name'),
        ),

        // ─── Priority ─────────────────────────────────
        _FieldWrapper(
          label: 'Priority',
          child: _buildPriorityField(),
        ),

        // ─── Policy ───────────────────────────────────
        _FieldWrapper(
          label: 'Policy',
          child: _buildDropdown(_policies, selectedPolicy, onPolicyChanged),
        ),

        // ─── Type ─────────────────────────────────────
        _FieldWrapper(
          label: 'Type',
          child: _buildDropdown(_types, selectedType, onTypeChanged),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBlue, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPriorityField() {
    return TextField(
      controller: priorityController,
      readOnly: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        suffixIcon: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
                onTap: onPriorityUp,
                child: const Icon(Icons.keyboard_arrow_up, size: 18)),
            InkWell(
                onTap: onPriorityDown,
                child: const Icon(Icons.keyboard_arrow_down, size: 18)),
          ],
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBlue, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      List<String> items, String value, ValueChanged<String> onChanged) {
    final safeValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          items: items
              .map((val) => DropdownMenuItem(value: val, child: Text(val)))
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}

// ─── Loading Field ────────────────────────────────────────

class _LoadingField extends StatelessWidget {
  const _LoadingField();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
          ),
          SizedBox(width: 10),
          Text('Loading tables...', style: TextStyle(color: Colors.black38)),
        ],
      ),
    );
  }
}

// ─── Field Wrapper ────────────────────────────────────────

class _FieldWrapper extends StatelessWidget {
  const _FieldWrapper({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 450,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1D242B),
              )),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
