import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/statistics_model_analyst.dart';

class ThreatAlertsCardAnalyst extends StatelessWidget {
  const ThreatAlertsCardAnalyst({
    super.key,
    required this.threats,
    required this.totalThreats,
    required this.onViewAll,
  });

  final List<ThreatDataAnalyst> threats;
  final int totalThreats;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2D40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Threat Alerts',
                style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: const Color(0xFF1D242B),
                ),
              ),
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'view all',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$totalThreats active threats',
            style: const TextStyle(
              color: Color.fromARGB(139, 0, 0, 0),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: threats.isEmpty
                ? const Center(
                    child: Text(
                      'No active threats',
                      style: TextStyle(color: Colors.black38),
                    ),
                  )
                : ListView.separated(
                    itemCount: threats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ThreatItemAnalyst(threats[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ThreatItemAnalyst extends StatelessWidget {
  const _ThreatItemAnalyst(this.d);
  final ThreatDataAnalyst d;

  Color get _levelColor {
    switch (d.level.toLowerCase()) {
      case 'critical':
        return const Color(0xFFF85149);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF8A93A6);
    }
  }

  String get _actionLabel => d.action.isNotEmpty ? d.action : 'Block';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080B0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2D40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  d.level,
                  style: TextStyle(
                    color: _levelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  d.time,
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: const Color(0xFFF2F5F8),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.ip,
                  style: GoogleFonts.roboto(fontSize: 14, color: Colors.white),
                ),
                Text(
                  d.type,
                  style: const TextStyle(
                    color: Color(0xFFF2F5F8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFD0D3D8)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'confidence: ${d.confidence}',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: const Color(0xFFCFD6E0),
                  ),
                ),
                Text(
                  _actionLabel,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: const Color(0xFFD5DADF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
