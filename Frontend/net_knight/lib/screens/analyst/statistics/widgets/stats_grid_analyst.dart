import 'package:flutter/material.dart';
import '../models/statistics_model_analyst.dart';

class StatsGridAnalyst extends StatelessWidget {
  const StatsGridAnalyst({super.key, required this.stats});

  final List<StatDataAnalyst> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, cs) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: cs.maxWidth > 600 ? 4 : 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.8,
        children: stats.map((d) => _StatCardAnalyst(d)).toList(),
      ),
    );
  }
}

class _StatCardAnalyst extends StatelessWidget {
  const _StatCardAnalyst(this.d);
  final StatDataAnalyst d;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D242B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: d.color.withOpacity(0.2),
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
            child: Text(
              d.trend,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          const Spacer(),
          Text(
            d.value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            d.label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}