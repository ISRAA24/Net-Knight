import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBlue = Color(0xFF3B82F6);
const _kBorder = Color(0xFF93C5FD);

class RuleForm extends StatelessWidget {
  const RuleForm({
    super.key,
    required this.tables,
    required this.chains,
    required this.selectedTableName,
    required this.selectedChainName,
    required this.ipSourceController,
    required this.ipDestController,
    required this.portDestController,
    required this.selectedInterface,
    required this.selectedProtocol,
    required this.selectedAction,
    required this.onTableChanged,
    required this.onChainChanged,
    required this.onInterfaceChanged,
    required this.onProtocolChanged,
    required this.onActionChanged,
    required this.onChanged,
  });

  final List<String> tables;
  final List<String> chains;
  final String selectedTableName;
  final String selectedChainName;
  final TextEditingController ipSourceController;
  final TextEditingController ipDestController;
  final TextEditingController portDestController;
  final String? selectedInterface;
  final String? selectedProtocol;
  final String? selectedAction;
  final ValueChanged<String> onTableChanged;
  final ValueChanged<String> onChainChanged;
  final ValueChanged<String?> onInterfaceChanged;
  final ValueChanged<String?> onProtocolChanged;
  final ValueChanged<String?> onActionChanged;
  final VoidCallback onChanged;

  static const _interfaces = ['ens33', 'eth0', 'lo'];
  static const _protocols = ['tcp', 'udp', 'icmp', 'any'];
  static const _actions = ['accept', 'reject', 'drop', 'log'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 60,
      runSpacing: 10,
      children: [
        // ─── Table Name ──────
        _FieldWrapper(
          label: 'Table name',
          child: tables.isEmpty
              ? const _LoadingField()
              : _buildDropdownRequired(
                  tables, selectedTableName, onTableChanged),
        ),

        // ─── Chain Name ─────
        _FieldWrapper(
          label: 'Chain name',
          child: chains.isEmpty
              ? const _LoadingField()
              : _buildDropdownRequired(
                  chains, selectedChainName, onChainChanged),
        ),

        // ─── IP Source ────────────────────────────────
        _FieldWrapper(
          label: 'IP source',
          child: _buildTextField(ipSourceController, '192.168.1.0/24'),
        ),

        // ─── IP Destination ───────────────────────────
        _FieldWrapper(
          label: 'IP destination',
          child: _buildTextField(ipDestController, '8.8.8.8'),
        ),

        // ─── Port Destination ─────────────────────────
        _FieldWrapper(
          label: 'Port destination',
          child: _buildTextField(portDestController, '80,443,22'),
        ),

        // ─── Interface ────────────────────────────────
        _FieldWrapper(
          label: 'Interface',
          child: _buildDropdownOptional(
            _interfaces,
            selectedInterface,
            onInterfaceChanged,
            'Select interface',
          ),
        ),

        // ─── Protocol ─────────────────────────────────
        _FieldWrapper(
          label: 'Protocol',
          child: _buildDropdownOptional(
            _protocols,
            selectedProtocol,
            onProtocolChanged,
            'Select protocol',
          ),
        ),

        // ─── Action ───────────────────────────────────
        _FieldWrapper(
          label: 'Action',
          child: _buildDropdownOptional(
            _actions,
            selectedAction,
            onActionChanged,
            'Select action',
          ),
        ),
      ],
    );
  }

  // ─── Required Dropdown ─────────────
  Widget _buildDropdownRequired(
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

  // ─── Optional Dropdown (hint) ─────────────────────
  Widget _buildDropdownOptional(List<String> items, String? value,
      ValueChanged<String?> onChanged, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          items: items
              .map((val) => DropdownMenuItem(value: val, child: Text(val)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ─── Text Field ───────────────────────────────────
  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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
          Text('Loading...', style: TextStyle(color: Colors.black38)),
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
                fontWeight: FontWeight.w600,
                color: Colors.black,
              )),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
