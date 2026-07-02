import 'package:flutter/material.dart';
import 'nat_form_fields.dart';

class DestinationNatForm extends StatelessWidget {
  const DestinationNatForm({
    super.key,
    required this.destIpController,
    required this.externalPortController,
    required this.internalPortController,
    required this.interfaces,
    required this.selectedProtocol,
    required this.selectedInterface,
    required this.onProtocolChanged,
    required this.onInterfaceChanged,
    required this.onChanged,
  });

  final TextEditingController destIpController;
  final TextEditingController externalPortController;
  final TextEditingController internalPortController;
  final List<String> interfaces;
  final String? selectedProtocol;
  final String? selectedInterface;
  final ValueChanged<String?> onProtocolChanged;
  final ValueChanged<String?> onInterfaceChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 40,
      runSpacing: 25,
      children: [
        NatDropdown(
          label: 'Protocol',
          items: const ['tcp', 'udp'],
          value: selectedProtocol,
          onChanged: (v) {
            onProtocolChanged(v);
            onChanged();
          },
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
        NatTextField(
          label: 'Destination IP',
          controller: destIpController,
          hint: '10.0.0.5',
          onChanged: (_) => onChanged(),
        ),
        NatTextField(
          label: 'External Port',
          controller: externalPortController,
          hint: '80',
          onChanged: (_) => onChanged(),
        ),
        NatTextField(
          label: 'Internal Port',
          controller: internalPortController,
          hint: '8080',
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
