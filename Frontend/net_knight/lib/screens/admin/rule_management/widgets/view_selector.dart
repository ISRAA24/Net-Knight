import 'package:flutter/material.dart';
import '../models/rule_management_model.dart';

class ViewSelector extends StatelessWidget {
  final RuleView active;
  final ValueChanged<RuleView> onChanged;

  const ViewSelector({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RadioOption(
          label: 'Firewall Rules',
          selected: active == RuleView.firewall,
          onTap: () => onChanged(RuleView.firewall),
        ),
        const SizedBox(width: 28),
        _RadioOption(
          label: 'NAT Rules',
          selected: active == RuleView.nat,
          onTap: () => onChanged(RuleView.nat),
        ),
      ],
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RadioOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? Colors.blue : Colors.black45, width: 2),
              ),
              child: selected
                  ? const Center(child: CircleAvatar(radius: 4, backgroundColor: Colors.blue))
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.black : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}