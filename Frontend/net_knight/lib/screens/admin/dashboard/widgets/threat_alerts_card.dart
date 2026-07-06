import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:net_knight/screens/admin/dashboard/models/stat_model.dart';
import '../../../../core/theme/nk_colors.dart';
import '../../../../core/theme/nk_text_styles.dart';

class ThreatAlertsCard extends StatelessWidget {
  final List<ThreatData> threats;
  final Future<Object?> Function() onViewAll;

  const ThreatAlertsCard({
    super.key,
    required this.threats,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
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
              // ⚠️ FIX: "view all" was a static Text with no tap handler at
              // all — onViewAll was accepted by the widget but never wired up.
              InkWell(
                onTap: () => onViewAll(),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'view all',
                    style: TextStyle(
                        color: NKColors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${threats.length} active threats',
              style: const TextStyle(
                  color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: threats.isEmpty
                ? const Center(
                    child: Text('No active threats',
                        style: TextStyle(color: Colors.black38)),
                  )
                : ListView.separated(
                    itemCount: threats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ThreatItem(data: threats[i]),
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

  Color get _levelColor => data.level == 'Critical' ? NKColors.amber : NKColors.red;

  // ⚠️ FIX: this previously always showed the hardcoded word "Block". It now
  // shows the real mitigation action returned by the backend (e.g.
  // "A2_TEMP_BLOCK"), falling back to "Block" only if the backend hasn't
  // recorded one (older documents created before the `action` field existed).
  String get _actionLabel => data.action.isNotEmpty ? data.action : 'Block';

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
                Text(data.level, style: TextStyle(color: _levelColor, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(data.time, style: GoogleFonts.jetBrainsMono(color: const Color(0xFFF2F5F8), fontSize: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.ip, style: GoogleFonts.jetBrainsMono(fontSize: 14, color: Colors.white)),
                Text(data.type, style: const TextStyle(color: Color(0xFFF2F5F8), fontSize: 12)),
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
                Text('confidence: ${data.confidence}', style: GoogleFonts.jetBrainsMono(color: const Color(0xFFCFD6E0), fontSize: 11)),
                Text(_actionLabel, style: const TextStyle(color: Color(0xFFD5DADF), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
