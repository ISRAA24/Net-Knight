import 'package:flutter/material.dart';
import 'package:net_knight/screens/admin/dashboard/models/stat_model.dart';
import '../../../../core/theme/nk_colors.dart';
import '../../../../core/theme/nk_text_styles.dart';

class SystemStatusCard extends StatelessWidget {
  final List<StatusData> statuses;
  final double cpuUsage;
  final double memoryUsage;
  final String packetsPerSec;
  final String activeConnections;

  const SystemStatusCard({
    super.key,
    required this.statuses,
    this.cpuUsage = 0,
    this.memoryUsage = 0,
    this.packetsPerSec = '0',
    this.activeConnections = '0',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NKColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Status', style: NKTextStyles.heading),
          const SizedBox(height: 4),
          Text('All systems operational', style: NKTextStyles.subheading),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: statuses.map((s) => _StatusTile(data: s)).toList(),
          ),
          const SizedBox(height: 24),
          _UsageBar(
            label: 'CPU usage',
            percent: cpuUsage.clamp(0.0, 1.0),
            value: '${(cpuUsage * 100).toStringAsFixed(0)}%',
          ),
          const SizedBox(height: 20),
          _UsageBar(
            label: 'Memory usage',
            percent: memoryUsage.clamp(0.0, 1.0),
            value: '${(memoryUsage * 100).toStringAsFixed(0)}%',
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: _InfoCard(value: packetsPerSec, label: 'packet/sec'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  value: activeConnections,
                  label: 'active connections',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final StatusData data;
  const _StatusTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width / 2 - 40).clamp(
      100.0,
      150.0,
    );
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: NKColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            data.status,
            style: TextStyle(
              color: data.color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final String label, value;
  final double percent;
  const _UsageBar({
    required this.label,
    required this.percent,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
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
                Color(0xFF0077C2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String value, label;
  const _InfoCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: NKColors.cardDark,
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
