import 'package:flutter/material.dart';
import '../models/rules_center_model_analyst.dart';

class ViewSelectorAnalyst extends StatelessWidget {
  const ViewSelectorAnalyst({
    super.key,
    required this.active,
    required this.onChanged,
  });

  final RuleViewAnalyst active;
  final ValueChanged<RuleViewAnalyst> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RadioOptionAnalyst(
          label: 'Firewall Rules',
          selected: active == RuleViewAnalyst.firewall,
          onTap: () => onChanged(RuleViewAnalyst.firewall),
        ),
        const SizedBox(width: 28),
        _RadioOptionAnalyst(
          label: 'NAT Rules',
          selected: active == RuleViewAnalyst.nat,
          onTap: () => onChanged(RuleViewAnalyst.nat),
        ),
      ],
    );
  }
}

class _RadioOptionAnalyst extends StatelessWidget {
  const _RadioOptionAnalyst({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
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
                border: Border.all(
                  color: selected
                      ? const Color(0xFF3B82F6)
                      : Colors.black45,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFF1D242B)
                    : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}