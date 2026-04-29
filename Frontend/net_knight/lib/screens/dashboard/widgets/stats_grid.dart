import 'package:flutter/material.dart';
import '../../../core/theme/nk_colors.dart';
import '../models/stat_data.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  static const _stats = [
    StatData('Total Threat', '16', '↗ +12%', NKColors.blue),
    StatData('Blocked Attack', '10', '↗ +8%', NKColors.amber),
    StatData('Active Rules', '12', '↗ +3%', NKColors.green),
    StatData('Pending Approvals', '0', '— 0%', Colors.purpleAccent),
  ];

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
          children: _stats.map((s) => _StatCard(data: s)).toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NKColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.2),
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
            child: Text(data.trend,
                style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
          const Spacer(),
          Text(data.value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(data.label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
