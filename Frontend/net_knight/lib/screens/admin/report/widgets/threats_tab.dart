import 'package:flutter/material.dart';
import '../models/report_model.dart';

class ThreatsTab extends StatelessWidget {
  final List<ThreatModel> threats;
  final String severityFilter;

  const ThreatsTab({super.key, required this.threats, required this.severityFilter});

  List<ThreatModel> get _filtered {
    if (severityFilter == 'all') return threats;
    return threats.where((t) => t.severity.toLowerCase() == severityFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Severity Chart - Last 14 days
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: const Color(0xFF1D242B),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Severity', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('Last 14 days threat activity', style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 12),
              Expanded(child: _SeverityChart(threats: _filtered)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFF9FAFB),
                  child: const Row(
                    children: [
                      _TH('Attack Name', flex: 3),
                      _TH('Attack Source', flex: 3),
                      _TH('Severity', flex: 2),
                      _TH('Status', flex: 2),
                      _TH('Date', flex: 2),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.black),
                if (_filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No threats match the selected filters.'),
                  )
                else
                  ..._filtered.map((r) => Column(
                    children: [
                      _ThreatRowWidget(r),
                      const Divider(height: 1, color: Colors.black),
                    ],
                  )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Helpers
class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    ),
  );
}

class _ThreatRowWidget extends StatelessWidget {
  final ThreatModel row;
  const _ThreatRowWidget(this.row);

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TD(row.attackName, flex: 3, bold: true),
        _VDivider(),
        _TD(row.attackSource, flex: 3),
        _VDivider(),
        _TD(row.severity, flex: 2),
        _VDivider(),
        _TD(row.status, flex: 2),
        _VDivider(),
        _TD(row.date, flex: 2),
      ],
    ),
  );
}

class _TD extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;
  const _TD(this.text, {required this.flex, this.bold = false});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Text(text, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    ),
  );
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, color: Colors.black);
}

class _SeverityChart extends StatelessWidget {
  final List<ThreatModel> threats;
  const _SeverityChart({required this.threats});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ScatterPainter(threats: threats),
    child: const SizedBox.expand(),
  );
}

class _ScatterPainter extends CustomPainter {
  final List<ThreatModel> threats;
  const _ScatterPainter({required this.threats});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < threats.length; i++) {
      final threat = threats[i];
      final x = (i % 14) * (size.width / 14);
      final y = size.height * (1 - (threat.severity == 'Critical' ? 0.9 : threat.severity == 'High' ? 0.7 : 0.4));
      final color = threat.severity == 'Critical' ? Colors.red : threat.severity == 'High' ? Colors.orange : Colors.green;

      canvas.drawCircle(Offset(x, y), 8, paint..color = color.withOpacity(0.3));
      canvas.drawCircle(Offset(x, y), 4, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}