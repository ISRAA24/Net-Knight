import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/ai_rule_model_analyst.dart';
import 'stat_card_analyst.dart';

class StatsRowAnalyst extends StatelessWidget {
  const StatsRowAnalyst({super.key, required this.stats});

  final AiRulesStatsAnalyst stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      (LucideIcons.clock, 'Pending Review', stats.pending),
      (LucideIcons.badgeCheck, 'Approved', stats.approved),
      (LucideIcons.circleX, 'Rejected', stats.rejected),
      (LucideIcons.sparkles, 'Total AI Rules', stats.total),
    ];

    return LayoutBuilder(
      builder: (_, cs) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: cs.maxWidth > 600 ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: items
            .map((e) => StatCardAnalyst(icon: e.$1, label: e.$2, value: e.$3))
            .toList(),
      ),
    );
  }
}