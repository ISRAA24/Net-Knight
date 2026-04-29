import 'package:flutter/material.dart';
import '../../../core/theme/nk_colors.dart';
import '../../../core/theme/nk_text_styles.dart';
import '../models/status_data.dart';

class SystemStatusCard extends StatelessWidget {
  const SystemStatusCard({super.key});

  static const _statuses = [
    StatusData('firewall engine', 'online', NKColors.green),
    StatusData('AI detection model', 'online', NKColors.green),
    StatusData('RL agent', 'Auto', NKColors.blue),
    StatusData('nftables controller', 'online', NKColors.green),
  ];

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
            children: _statuses.map((s) => _StatusTile(data: s)).toList(),
          ),
          const SizedBox(height: 24),
          const _UsageBar(label: 'CPU usage', percent: 0.67, value: '67%'),
          const SizedBox(height: 20),
          const _UsageBar(label: 'Memory usage', percent: 0.71, value: '71%'),
          const SizedBox(height: 30),
          Row(
            children: const [
              Expanded(child: _InfoCard(value: '11,456', label: 'packet/sec')),
              SizedBox(width: 12),
              Expanded(
                  child:
                      _InfoCard(value: '1,449', label: 'active connections')),
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
    final width =
        (MediaQuery.of(context).size.width / 2 - 40).clamp(100.0, 150.0);
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
          Text(data.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text(data.status,
              style: TextStyle(
                  color: data.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final String label, value;
  final double percent;
  const _UsageBar(
      {required this.label, required this.percent, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 10,
            backgroundColor: Colors.white,
            valueColor: const AlwaysStoppedAnimation<Color>(NKColors.primary),
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
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
