import 'package:flutter/material.dart';
import 'nat_form_fields.dart';

class MasqueradeForm extends StatelessWidget {
  const MasqueradeForm({
    super.key,
    required this.sourceIpController,
    required this.interfaces,
    required this.selectedInterface,
    required this.onInterfaceChanged,
    required this.onChanged,
  });

  final TextEditingController sourceIpController;
  final List<String> interfaces;
  final String? selectedInterface;
  final ValueChanged<String?> onInterfaceChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 40,
      runSpacing: 25,
      children: [
        NatTextField(
          label: 'Source IP',
          controller: sourceIpController,
          hint: '192.168.1.0/24',
          onChanged: (_) => onChanged(),
        ),
        NatDropdown(
          label: 'Output Interface',
          items: interfaces,
          value: selectedInterface,
          onChanged: (v) {
            onInterfaceChanged(v);
            onChanged();
          },
        ),
      ],
    );
  }
}
