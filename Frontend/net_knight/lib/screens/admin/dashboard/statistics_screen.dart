import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:net_knight/core/network/dashboard_socket_service.dart';
import 'package:net_knight/main.dart';
import 'package:net_knight/screens/admin/dashboard/widgets/sidebar.dart';
import 'package:provider/provider.dart';

import 'models/stat_model.dart';
import 'services/stat_service.dart';
import 'widgets/stats_grid.dart';
import 'widgets/chart_section.dart';
import 'widgets/system_status_card.dart';
import 'widgets/threat_alerts_card.dart';

class StatisticsScreenAdmin extends StatefulWidget {
  const StatisticsScreenAdmin({super.key});

  @override
  State<StatisticsScreenAdmin> createState() => _StatisticsScreenAdminState();
}

class _StatisticsScreenAdminState extends State<StatisticsScreenAdmin> {
  final _service = StatService();
  final _socket = DashboardSocketService.instance;

  StatData? _stats;
  List<ThreatData> _threats = [];
  List<StatusData> _statuses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _socket.addListener(_onRealtimeUpdate);
  }

  @override
  void dispose() {
    _socket.removeListener(_onRealtimeUpdate);
    super.dispose();
  }

  void _onRealtimeUpdate() {
    if (!mounted) return;
    setState(() {
      // بندمج الـ realtime counters (لو وصلت) مع الـ trends اللي أصلاً عندنا
      final rt = _socket.stats;
      _stats = StatData(
        totalThreat: rt.totalThreats.toString(),
        blockedAttack: rt.blockedAttacks.toString(),
        activeRules: rt.activeRules.toString(),
        pendingApprovals: rt.pendingApprovals.toString(),
        trend: _stats?.trend ?? '↗ 0%',
        blockedTrend: _stats?.blockedTrend ?? '↗ 0%',
        activeTrend: _stats?.activeTrend ?? '↗ 0%',
        pendingTrend: _stats?.pendingTrend ?? '— 0%',
      );
    });
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      _stats = await _service.getDashboardStats();
      _threats = await _service.getThreats();
      _statuses = await _service.getSystemStatus();
    } catch (e) {
      print('Error loading stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _socket.metrics;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TopBar(title: 'Statistics'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatsGrid(stats: _stats),
                        const SizedBox(height: 20),
                        ChartSection(
                          outboundSpots: metrics.outboundSpots,
                          inboundSpots: metrics.inboundSpots,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SystemStatusCard(
                                statuses: _statuses,
                                cpuUsage: metrics.cpuUsage,
                                memoryUsage: metrics.memoryUsage,
                                packetsPerSec: metrics.packetsPerSec,
                                activeConnections: metrics.activeConnections,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ThreatAlertsCard(
                                threats: _threats,
                                onViewAll: () =>
                                    Navigator.pushNamed(context, '/reports'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.rajdhani(fontSize: 26, fontWeight: FontWeight.w500)),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.bell, size: 22),
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}