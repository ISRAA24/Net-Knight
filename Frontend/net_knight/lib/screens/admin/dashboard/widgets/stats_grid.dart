import 'package:flutter/material.dart';
import '../../../../core/theme/nk_colors.dart';
import '../models/stat_model.dart';

class StatsGrid extends StatelessWidget {
  final StatData? stats;
  const StatsGrid({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 2,
          children: [
            _StatCard(
              label: 'Total Threat',
              value: stats?.totalThreat ?? '0',
              trend: stats?.trend ?? '↗ 0%',
              color: NKColors.blue,
            ),
            _StatCard(
              label: 'Blocked Attack',
              value: stats?.blockedAttack ?? '0',
              trend: stats?.blockedTrend ?? '↗ 0%',
              color: NKColors.amber,
            ),
            _StatCard(
              label: 'Active Rules',
              value: stats?.activeRules ?? '0',
              trend: stats?.activeTrend ?? '↗ 0%',
              color: NKColors.green,
            ),
            _StatCard(
              label: 'Pending Approvals',
              value: stats?.pendingApprovals ?? '0',
              trend: stats?.pendingTrend ?? '— 0%',
              color: Colors.purpleAccent,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.trend, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NKColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Text(trend, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}