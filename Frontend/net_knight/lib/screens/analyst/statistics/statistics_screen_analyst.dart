import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:net_knight/core/network/base_services.dart';

import '../ai_generated_rules/widgets/sidebar_analyst.dart';
import 'models/statistics_model_analyst.dart';
import 'services/statistics_service_analyst.dart';
import 'widgets/chart_section_analyst.dart';
import 'widgets/stats_grid_analyst.dart';
import 'widgets/system_status_card_analyst.dart';
import 'widgets/threat_alerts_card_analyst.dart';

class StatisticsScreenAnalyst extends StatefulWidget {
  const StatisticsScreenAnalyst({super.key});

  @override
  State<StatisticsScreenAnalyst> createState() =>
      _StatisticsScreenAnalystState();
}

class _StatisticsScreenAnalystState extends State<StatisticsScreenAnalyst> {
  final _service = StatisticsServiceAnalyst();

  StatisticsSummaryAnalyst? _data;
  bool _isLoading = true;
  String? _error;

  // بيانات اليوزر
  String _username = '';
  String _role = '';
  String _initials = '';

  // Chart series — static لأن الـ chart data مش بييجي من الـ API دلوقتي
  // TODO: لو الـ API هيرجع chart data استبدلي الـ _chartSeries بالداتا الجاية
  static final _chartSeries = [
    ChartSeriesAnalyst(
      color: const Color(0xFF388BFD),
      label: 'Outbound',
      spots: [
        FlSpot(0, 78), FlSpot(1, 92), FlSpot(2, 35), FlSpot(3, 42),
        FlSpot(4, 65), FlSpot(5, 48), FlSpot(6, 25), FlSpot(7, 55),
        FlSpot(8, 20), FlSpot(9, 12),
      ],
    ),
    ChartSeriesAnalyst(
      color: const Color(0xFF56CFE1),
      label: 'Inbound',
      spots: [
        FlSpot(0, 60), FlSpot(1, 70), FlSpot(2, 28), FlSpot(3, 30),
        FlSpot(4, 50), FlSpot(5, 40), FlSpot(6, 18), FlSpot(7, 35),
        FlSpot(8, 15), FlSpot(9, 8),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadData();
  }

  Future<void> _loadUserInfo() async {
    // final user = await UserService().getCurrentUser();
    setState(() {
      _username = 'Analyst';
      _role = 'Analyst';
      _initials = 'AN';
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _service.getStatistics();
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load statistics');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static final _fallbackStats = [
    StatDataAnalyst(
        label: 'Total Threat',
        value: '16',
        trend: '↗ +12%',
        color: const Color(0xFF3B82F6)),
    StatDataAnalyst(
        label: 'Blocked Attack',
        value: '10',
        trend: '↗ +8%',
        color: const Color(0xFFF59E0B)),
    StatDataAnalyst(
        label: 'Active Rules',
        value: '12',
        trend: '↗ +3%',
        color: const Color(0xFF22C55E)),
    StatDataAnalyst(
        label: 'Pending Approvals',
        value: '0',
        trend: '— 0%',
        color: Colors.purpleAccent),
  ];

  static final _fallbackStatuses = [
    StatusDataAnalyst(
        name: 'firewall engine',
        status: 'online',
        color: const Color(0xFF22C55E)),
    StatusDataAnalyst(
        name: 'AI detection model',
        status: 'online',
        color: const Color(0xFF22C55E)),
    StatusDataAnalyst(
        name: 'RL agent', status: 'Auto', color: const Color(0xFF3B82F6)),
    StatusDataAnalyst(
        name: 'nftables controller',
        status: 'online',
        color: const Color(0xFF22C55E)),
  ];

  static final _fallbackThreats = [
    ThreatDataAnalyst(
        ip: '185.220.101.42',
        type: 'DDoS',
        level: 'Critical',
        confidence: '98%',
        time: '22:08:53'),
    ThreatDataAnalyst(
        ip: '103.21.244.0',
        type: 'Port Scan',
        level: 'High',
        confidence: '94%',
        time: '22:09:11'),
    ThreatDataAnalyst(
        ip: '45.33.32.156',
        type: 'SQL Injection',
        level: 'Critical',
        confidence: '91%',
        time: '22:10:02'),
    ThreatDataAnalyst(
        ip: '77.91.68.21',
        type: 'XSS Attempt',
        level: 'High',
        confidence: '88%',
        time: '22:11:47'),
    ThreatDataAnalyst(
        ip: '198.51.100.23',
        type: 'Port Scan',
        level: 'High',
        confidence: '85%',
        time: '22:12:30'),
    ThreatDataAnalyst(
        ip: '203.0.113.50',
        type: 'DDoS',
        level: 'Critical',
        confidence: '96%',
        time: '22:13:15'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          SidebarAnalyst(
            activeRoute: '/statistics',
            username: _username,
            role: _role,
            initials: _initials,
          ),
          Expanded(
            child: Column(
              children: [
                const _TopBarAnalyst(title: 'Statistics'),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    final stats = _data?.stats ?? _fallbackStats;
    final statuses = _data?.systemStatuses ?? _fallbackStatuses;
    final threats = _data?.threats ?? _fallbackThreats;
    final cpu = _data?.cpuUsage ?? 0.67;
    final memory = _data?.memoryUsage ?? 0.71;
    final packets = _data?.packetsPerSec ?? '11,456';
    final connections = _data?.activeConnections ?? '1,449';
    final totalThreats = _data?.totalThreats ?? 16;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatsGridAnalyst(stats: stats),
            const SizedBox(height: 20),
            ChartSectionAnalyst(series: _chartSeries),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SystemStatusCardAnalyst(
                    statuses: statuses,
                    cpuUsage: cpu,
                    memoryUsage: memory,
                    packetsPerSec: packets,
                    activeConnections: connections,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ThreatAlertsCardAnalyst(
                    threats: threats,
                    totalThreats: totalThreats,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────
class _TopBarAnalyst extends StatelessWidget {
  const _TopBarAnalyst({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.rajdhani(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1D242B),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (_) => const NotificationsScreenAnalyst()));
                },
                child: const Icon(
                  LucideIcons.bell,
                  size: 22,
                  color: Color(0xFF1D242B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black12, height: 1),
        ],
      ),
    );
  }
}