import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/statistics_model_analyst.dart';

class ChartSectionAnalyst extends StatelessWidget {
  const ChartSectionAnalyst({super.key, required this.series});

  final List<ChartSeriesAnalyst> series;

  static const _xLabels = [
    'TLS', 'HTTP', 'FTP', 'SSH', 'TCP',
    'UDP', 'ICMP', 'DNS', 'DHCP', 'Other',
  ];

  static FlLine _gridLine() =>
      const FlLine(color: Colors.black12, strokeWidth: 1);

  static SideTitles _hiddenTitles() => const SideTitles(showTitles: false);

  LineChartData _chartData() => LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: 20,
          verticalInterval: 1,
          getDrawingHorizontalLine: (_) => _gridLine(),
          getDrawingVerticalLine: (_) => _gridLine(),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.black26),
        ),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: _hiddenTitles()),
          topTitles: AxisTitles(sideTitles: _hiddenTitles()),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 30,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(color: Colors.black54, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= _xLabels.length) return const SizedBox();
                return Text(
                  _xLabels[i],
                  style: const TextStyle(color: Colors.black54, fontSize: 10),
                );
              },
            ),
          ),
        ),
        lineBarsData: series.map(_toLine).toList(),
      );

  static LineChartBarData _toLine(ChartSeriesAnalyst s) => LineChartBarData(
        spots: s.spots,
        isCurved: true,
        color: s.color,
        barWidth: 2,
        dotData: FlDotData(
          show: true,
          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
            radius: 3,
            color: s.color,
            strokeWidth: 1,
            strokeColor: Colors.white,
          ),
        ),
        belowBarData: BarAreaData(show: false),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2D40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Network Traffic',
            style: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: const Color(0xFF1D242B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Real-Time bandwidth monitoring',
            style: GoogleFonts.roboto(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Expanded(child: LineChart(_chartData())),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: series
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _LegendAnalyst(s.color, s.label),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LegendAnalyst extends StatelessWidget {
  const _LegendAnalyst(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      );
}