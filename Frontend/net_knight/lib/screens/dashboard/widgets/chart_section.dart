import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/nk_colors.dart';
import '../../../core/theme/nk_text_styles.dart';

class ChartSection extends StatelessWidget {
  const ChartSection({super.key});

  static const _xLabels = [
    'Figma',
    'Sketch',
    'XD',
    'PS',
    'AI',
    'CorelDRAW',
    'InDesign',
    'Canva',
    'Webflow',
    'Affinity',
    'Marker',
    'Figma',
  ];

  static final _series = [
    _SeriesData(color: NKColors.primary, label: '2020', spots: [
      FlSpot(0, 78),
      FlSpot(1, 77),
      FlSpot(2, 45),
      FlSpot(3, 25),
      FlSpot(4, 18),
      FlSpot(5, 65),
      FlSpot(6, 95),
      FlSpot(7, 75),
      FlSpot(8, 75),
      FlSpot(9, 100),
      FlSpot(10, 88),
      FlSpot(11, 82),
    ]),
    _SeriesData(color: NKColors.green, label: '2021', spots: [
      FlSpot(0, 52),
      FlSpot(1, 22),
      FlSpot(2, 60),
      FlSpot(3, 10),
      FlSpot(4, 58),
      FlSpot(5, 70),
      FlSpot(6, 30),
      FlSpot(7, 52),
      FlSpot(8, 20),
      FlSpot(9, 63),
      FlSpot(10, 28),
      FlSpot(11, 14),
    ]),
    _SeriesData(color: NKColors.amber, label: '2022', spots: [
      FlSpot(0, 86),
      FlSpot(1, 78),
      FlSpot(2, 60),
      FlSpot(3, 35),
      FlSpot(4, 15),
      FlSpot(5, 67),
      FlSpot(6, 90),
      FlSpot(7, 75),
      FlSpot(8, 75),
      FlSpot(9, 98),
      FlSpot(10, 87),
      FlSpot(11, 82),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NKColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Network Traffic', style: NKTextStyles.heading),
          const SizedBox(height: 4),
          Text('Real-Time bandwidth monitoring',
              style: NKTextStyles.subheading),
          const SizedBox(height: 20),
          Expanded(child: LineChart(_buildChartData())),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _series
                .map((s) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _LegendItem(color: s.color, label: s.label),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        horizontalInterval: 20,
        verticalInterval: 1,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: Colors.black12, strokeWidth: 1),
        getDrawingVerticalLine: (_) =>
            const FlLine(color: Colors.black12, strokeWidth: 1),
      ),
      borderData:
          FlBorderData(show: true, border: Border.all(color: Colors.black26)),
      titlesData: FlTitlesData(
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            reservedSize: 30,
            getTitlesWidget: (value, _) => Text(
              value.toInt().toString(),
              style: const TextStyle(color: Colors.black54, fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, _) {
              final i = value.toInt();
              if (i < 0 || i >= _xLabels.length) return const SizedBox();
              return Text(_xLabels[i],
                  style: const TextStyle(color: Colors.black54, fontSize: 10));
            },
          ),
        ),
      ),
      lineBarsData: _series.map(_buildLine).toList(),
    );
  }

  LineChartBarData _buildLine(_SeriesData s) {
    return LineChartBarData(
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
  }
}

class _SeriesData {
  final Color color;
  final String label;
  final List<FlSpot> spots;
  const _SeriesData(
      {required this.color, required this.label, required this.spots});
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(color: Colors.black54, fontSize: 11)),
      ],
    );
  }
}
