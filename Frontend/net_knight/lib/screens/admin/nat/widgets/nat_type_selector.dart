import 'package:flutter/material.dart';
import '../models/nat_model.dart';

const _kBlue = Color(0xFF3B82F6);

class NatTypeSelector extends StatelessWidget {
  const NatTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final NatType selected;
  final ValueChanged<NatType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RadioButton(
          type: NatType.masquerade,
          label: 'Masquerade NAT',
          selected: selected,
          onChanged: onChanged,
        ),
        const SizedBox(width: 30),
        _RadioButton(
          type: NatType.source,
          label: 'Source NAT',
          selected: selected,
          onChanged: onChanged,
        ),
        const SizedBox(width: 30),
        _RadioButton(
          type: NatType.destination,
          label: 'Destination NAT',
          selected: selected,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _RadioButton extends StatelessWidget {
  const _RadioButton({
    required this.type,
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final NatType type;
  final String label;
  final NatType selected;
  final ValueChanged<NatType> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(type),
      child: Row(
        children: [
          Radio<NatType>(
            value: type,
            groupValue: selected,
            onChanged: (v) => onChanged(v!),
            activeColor: _kBlue,
          ),
          Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
