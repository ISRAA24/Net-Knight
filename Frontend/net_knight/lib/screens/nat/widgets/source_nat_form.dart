import 'package:flutter/material.dart';
import 'nat_form_fields.dart';

class SourceNatForm extends StatelessWidget {
  const SourceNatForm({
    super.key,
    required this.sourceIpController,
    required this.newSourceIpController,
    required this.selectedInterface,
    required this.onInterfaceChanged,
    required this.onChanged,
  });

  final TextEditingController sourceIpController;
  final TextEditingController newSourceIpController;
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
          items: const ['ens33', 'ens37'],
          value: selectedInterface,
          onChanged: (v) {
            onInterfaceChanged(v);
            onChanged();
          },
        ),
        NatTextField(
          label: 'New Source IP',
          controller: newSourceIpController,
          hint: '203.0.113.5',
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
