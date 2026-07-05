import 'package:flutter/material.dart';
import 'package:net_knight/core/theme/nk_colors.dart';
import '../models/reports_model_analyst.dart';
import 'table_helpers.dart';

class ThreatsTabContent extends StatelessWidget {
  final List<ThreatModel> threats;
  final String severityFilter;
  final String dateFilter;

  const ThreatsTabContent({
    super.key,
    required this.threats,
    required this.severityFilter,
    required this.dateFilter,
  });

  List<ThreatModel> get filtered => severityFilter == 'all severity' 
      ? threats 
      : threats.where((t) => t.severity.toLowerCase() == severityFilter.toLowerCase()).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 750,
          height: 260,
          decoration: BoxDecoration(
            color: NKColors.cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:  [
                    Text('Severity', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Last 7 days threat activity', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    SizedBox(height: 12),
                    Expanded(child: _SeverityChart(threats: filtered)),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              const Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendDot(color: NKColors.red, label: 'critical, high'),
                  SizedBox(height: 8),
                  _LegendDot(color: NKColors.amber, label: 'medium'),
                  SizedBox(height: 8),
                  _LegendDot(color: NKColors.green, label: 'low'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        buildDataTable(
          headers: ['Attack Name', 'Source', 'Severity', 'Status', 'Date'],
          rows: filtered.map((t) => [t.attackName, t.attackSource, t.severity, t.status, t.date]).toList(),
          flexes: [3, 3, 2, 2, 2],
        ),
      ],
    );
  }
}

// Dynamic Chart - Last 7 days
class _SeverityChart extends StatelessWidget {
  final List<ThreatModel> threats;
  const _SeverityChart({required this.threats});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _ScatterPainter(_generateDots()),
        child: const SizedBox.expand(),
      );

  List<_Dot> _generateDots() {
    final dots = <_Dot>[];
    final recent = threats.take(7).toList();

    int high = 0, medium = 0, low = 0;

    for (final t in recent) {
      final s = t.severity.toLowerCase();
      if (s.contains('critical') || s.contains('high')) {
        high++;
      } else if (s.contains('medium')) {
        medium++;
      } else {
        low++;
      }
    }

    if (high > 0) dots.add(_Dot(2.0, 9.0, NKColors.red));
    if (medium > 0) dots.add(_Dot(4.0, 5.5, NKColors.amber));
    if (low > 0) dots.add(_Dot(6.0, 2.5, NKColors.green));

    return dots;
  }
}

class _Dot {
  final double x, y;
  final Color color;
  const _Dot(this.x, this.y, this.color);
}

class _ScatterPainter extends CustomPainter {
  const _ScatterPainter(this.dots);
  final List<_Dot> dots;

  @override
  void paint(Canvas canvas, Size size) {
    const lp = 28.0, bp = 20.0, tp = 10.0, rp = 8.0;
    final w = size.width - lp - rp;
    final h = size.height - tp - bp;

    final ax = Paint()..color = Colors.white24..strokeWidth = 0.8;
    final gr = Paint()..color = Colors.white12..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final v = i * 3;
      final py = tp + h * (1 - v / 12);
      canvas.drawLine(Offset(lp, py), Offset(lp + w, py), i == 0 ? ax : gr);
    }
    for (int i = 0; i <= 4; i++) {
      final v = i * 3;
      final px = lp + w * (v / 12);
      canvas.drawLine(Offset(px, tp), Offset(px, tp + h), i == 0 ? ax : gr);
    }

    for (final d in dots) {
      final px = lp + (d.x / 12) * w;
      final py = tp + (1 - d.y / 12) * h;
      canvas.drawCircle(Offset(px, py), 9, Paint()..color = d.color.withOpacity(0.2));
      canvas.drawCircle(Offset(px, py), 5.5, Paint()..color = d.color);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      );
}