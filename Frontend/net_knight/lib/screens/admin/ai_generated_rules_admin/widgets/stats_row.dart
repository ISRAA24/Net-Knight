import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/ai_rule_model.dart';

class StatsRow extends StatelessWidget {
  final List<AiRuleModel> rules;
  final bool autoApprove;
  final VoidCallback onToggleAuto;

  const StatsRow({
    super.key,
    required this.rules,
    required this.autoApprove,
    required this.onToggleAuto,
  });

  int get pending => rules.where((r) => r.status == AiRuleStatus.pending).length;
  int get approved => rules.where((r) => r.status == AiRuleStatus.approved).length;
  int get rejected => rules.where((r) => r.status == AiRuleStatus.rejected).length;
  int get total => rules.length;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            _StatCard(icon: LucideIcons.clock, label: 'Pending Review', value: pending),
            _StatCard(icon: LucideIcons.badgeCheck, label: 'Approved', value: approved),
            _StatCard(icon: LucideIcons.circleX, label: 'Rejected', value: rejected),
            _StatCard(icon: LucideIcons.sparkles, label: 'Total AI Rules', value: total),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D242B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}