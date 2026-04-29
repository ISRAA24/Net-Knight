import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/nk_colors.dart';
import '../../../core/theme/nk_text_styles.dart';
import '../models/threat_data.dart';

class ThreatAlertsCard extends StatelessWidget {
  const ThreatAlertsCard({super.key});

  static const _threats = [
    ThreatData(
        ip: '185.220.101.42',
        type: 'DDoS',
        level: 'Critical',
        confidence: '98%',
        time: '22:08:53'),
    ThreatData(
        ip: '103.21.244.0',
        type: 'Port Scan',
        level: 'High',
        confidence: '94%',
        time: '22:09:11'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NKColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NKColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Threat Alerts', style: NKTextStyles.heading),
              const Text('view all',
                  style: TextStyle(
                      color: NKColors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('16 active threats',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: ListView.separated(
              itemCount: _threats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ThreatItem(data: _threats[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreatItem extends StatelessWidget {
  final ThreatData data;
  const _ThreatItem({required this.data});

  Color get _levelColor =>
      data.level == 'Critical' ? NKColors.amber : NKColors.red;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080B0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NKColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data.level,
                    style: TextStyle(
                        color: _levelColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text(data.time,
                    style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFFF2F5F8), fontSize: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.ip,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 14, color: Colors.white)),
                Text(data.type,
                    style: const TextStyle(
                        color: Color(0xFFF2F5F8), fontSize: 12)),
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
                Text('confidence: ${data.confidence}',
                    style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFFCFD6E0), fontSize: 11)),
                GestureDetector(
                  onTap: () {},
                  child: const Text('Block',
                      style: TextStyle(color: Color(0xFFD5DADF), fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
