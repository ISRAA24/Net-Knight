import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/nk_colors.dart';
import '../../../../core/theme/nk_text_styles.dart';

class ChartSection extends StatelessWidget {
  final List<FlSpot> outboundSpots;
  final List<FlSpot> inboundSpots;

  const ChartSection({
    super.key,
    this.outboundSpots = const [],
    this.inboundSpots = const [],
  });

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
          Text('Real-Time bandwidth monitoring', style: NKTextStyles.subheading),
          const SizedBox(height: 20),
          Expanded(child: LineChart(_buildChartData())),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: NKColors.primary, label: 'Outbound'),
              _LegendItem(color: NKColors.green, label: 'Inbound'),
            ],
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
        getDrawingHorizontalLine: (_) => const FlLine(color: Colors.black12, strokeWidth: 1),
        getDrawingVerticalLine: (_) => const FlLine(color: Colors.black12, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: Colors.black26)),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
            getTitlesWidget: (value, _) => Text(
              ['TLS', 'HTTP', 'FTP', 'SSH', 'TCP', 'UDP', 'ICMP', 'DNS', 'DHCP', 'Other'][value.toInt()],
              style: const TextStyle(color: Colors.black54, fontSize: 10),
            ),
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: outboundSpots.isNotEmpty ? outboundSpots : _defaultOutbound,
          isCurved: true,
          color: NKColors.primary,
          barWidth: 2,
          dotData: FlDotData(show: true),
        ),
        LineChartBarData(
          spots: inboundSpots.isNotEmpty ? inboundSpots : _defaultInbound,
          isCurved: true,
          color: NKColors.green,
          barWidth: 2,
          dotData: FlDotData(show: true),
        ),
      ],
    );
  }

  static final List<FlSpot> _defaultOutbound = [
    FlSpot(0, 78),
    FlSpot(1, 92),
    FlSpot(2, 35),
    FlSpot(3, 42),
    FlSpot(4, 65),
    FlSpot(5, 48),
    FlSpot(6, 25),
    FlSpot(7, 55),
    FlSpot(8, 20),
    FlSpot(9, 12),
  ];

  static final List<FlSpot> _defaultInbound = [
    FlSpot(0, 60),
    FlSpot(1, 70),
    FlSpot(2, 28),
    FlSpot(3, 30),
    FlSpot(4, 50),
    FlSpot(5, 40),
    FlSpot(6, 18),
    FlSpot(7, 35),
    FlSpot(8, 15),
    FlSpot(9, 8),
  ];
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
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
      ],
    );
  }
}