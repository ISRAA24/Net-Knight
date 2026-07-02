import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/statistics_model_analyst.dart';

class SystemStatusCardAnalyst extends StatelessWidget {
  const SystemStatusCardAnalyst({
    super.key,
    required this.statuses,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.packetsPerSec,
    required this.activeConnections,
  });

  final List<StatusDataAnalyst> statuses;
  final double cpuUsage;
  final double memoryUsage;
  final String packetsPerSec;
  final String activeConnections;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Status',
            style: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: const Color(0xFF1D242B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All systems operational',
            style: GoogleFonts.roboto(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: statuses.map((s) => _StatusTileAnalyst(s)).toList(),
          ),
          const SizedBox(height: 24),
          _UsageBarAnalyst('CPU usage', cpuUsage,
              '${(cpuUsage * 100).toInt()}%'),
          const SizedBox(height: 20),
          _UsageBarAnalyst('Memory usage', memoryUsage,
              '${(memoryUsage * 100).toInt()}%'),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                  child: _InfoCardAnalyst(packetsPerSec, 'packet/sec')),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      _InfoCardAnalyst(activeConnections, 'active connections')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTileAnalyst extends StatelessWidget {
  const _StatusTileAnalyst(this.d);
  final StatusDataAnalyst d;

  @override
  Widget build(BuildContext context) {
    final width =
        (MediaQuery.of(context).size.width / 2 - 40).clamp(100.0, 150.0);
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1D242B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            d.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            d.status,
            style: TextStyle(
              color: d.color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageBarAnalyst extends StatelessWidget {
  const _UsageBarAnalyst(this.label, this.percent, this.value);
  final String label;
  final double percent;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: _kStyle),
            Text(value, style: _kStyle),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromARGB(47, 0, 0, 0),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF0077C2)),
            ),
          ),
        ),
      ],
    );
  }

  static const _kStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );
}

class _InfoCardAnalyst extends StatelessWidget {
  const _InfoCardAnalyst(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1D242B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}