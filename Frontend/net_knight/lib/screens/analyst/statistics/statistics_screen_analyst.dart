import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:net_knight/core/network/base_services.dart';
import 'package:net_knight/core/network/dashboard_socket_service.dart';

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
  final _socket = DashboardSocketService.instance;

  StatisticsSummaryAnalyst? _data;
  bool _isLoading = true;
  String? _error;

  String _username = 'User';
  String _role = '';
  String _initials = 'U';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadData();
    _socket.addListener(_onRealtimeUpdate);
  }

  @override
  void dispose() {
    _socket.removeListener(_onRealtimeUpdate);
    super.dispose();
  }

  void _onRealtimeUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadUserInfo() async {
    final username = await TokenStorage.getUsername();
    final role = await TokenStorage.getRole();
    if (mounted) {
      setState(() {
        _username = username;
        _role = role;
        _initials = _computeInitials(username);
      });
    }
  }

  String _computeInitials(String name) {
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return 'U';
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
      value: '0',
      trend: '— 0%',
      color: const Color(0xFF3B82F6),
    ),
    StatDataAnalyst(
      label: 'Blocked Attack',
      value: '0',
      trend: '— 0%',
      color: const Color(0xFFF59E0B),
    ),
    StatDataAnalyst(
      label: 'Active Rules',
      value: '0',
      trend: '— 0%',
      color: const Color(0xFF22C55E),
    ),
    StatDataAnalyst(
      label: 'Pending Approvals',
      value: '0',
      trend: '— 0%',
      color: Colors.purpleAccent,
    ),
  ];

  static final _fallbackStatuses = [
    StatusDataAnalyst(
      name: 'firewall engine',
      status: 'online',
      color: const Color(0xFF22C55E),
    ),
    StatusDataAnalyst(
      name: 'AI detection model',
      status: 'online',
      color: const Color(0xFF22C55E),
    ),
    StatusDataAnalyst(
      name: 'RL agent',
      status: 'Auto',
      color: const Color(0xFF3B82F6),
    ),
    StatusDataAnalyst(
      name: 'nftables controller',
      status: 'online',
      color: const Color(0xFF22C55E),
    ),
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
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    final metrics = _socket.metrics;
    final rt = _socket.stats;

    // الـ stats cards: لو الـ socket بعت أرقام حقيقية (rt) نستخدمها،
    // وإلا نرجع لـ _data (HTTP) أو fallback.
    final stats = <StatDataAnalyst>[
      StatDataAnalyst(
        label: 'Total Threat',
        value: rt.totalThreats.toString(),
        trend: _data?.stats.isNotEmpty == true ? _data!.stats[0].trend : '— 0%',
        color: const Color(0xFF3B82F6),
      ),
      StatDataAnalyst(
        label: 'Blocked Attack',
        value: rt.blockedAttacks.toString(),
        trend: (_data?.stats.length ?? 0) > 1 ? _data!.stats[1].trend : '— 0%',
        color: const Color(0xFFF59E0B),
      ),
      StatDataAnalyst(
        label: 'Active Rules',
        value: rt.activeRules.toString(),
        trend: (_data?.stats.length ?? 0) > 2 ? _data!.stats[2].trend : '— 0%',
        color: const Color(0xFF22C55E),
      ),
      StatDataAnalyst(
        label: 'Pending Approvals',
        value: rt.pendingApprovals.toString(),
        trend: (_data?.stats.length ?? 0) > 3 ? _data!.stats[3].trend : '— 0%',
        color: Colors.purpleAccent,
      ),
    ];

    final statuses = _data?.systemStatuses.isNotEmpty == true
        ? _data!.systemStatuses
        : _fallbackStatuses;
    final threats = _data?.threats ?? const [];
    final totalThreats = rt.totalThreats;

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
            ChartSectionAnalyst(
              series: [
                ChartSeriesAnalyst(
                  color: const Color(0xFF388BFD),
                  label: 'Outbound',
                  spots: metrics.outboundSpots,
                ),
                ChartSeriesAnalyst(
                  color: const Color(0xFF56CFE1),
                  label: 'Inbound',
                  spots: metrics.inboundSpots,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // ⚠️ FIX: SystemStatusCardAnalyst and ThreatAlertsCardAnalyst were
            // both wrapped in `Expanded` inside this Row but the Row itself
            // has no bounded height (it's inside a SingleChildScrollView), so
            // Expanded here has nothing to expand into. We give the Row a
            // fixed height so ThreatAlertsCardAnalyst's `Expanded`/`height:
            // double.infinity` internals have something concrete to size
            // against, matching how the admin dashboard lays this out.
            SizedBox(
              height: 480,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SystemStatusCardAnalyst(
                      statuses: statuses,
                      cpuUsage: metrics.cpuUsage,
                      memoryUsage: metrics.memoryUsage,
                      packetsPerSec: metrics.packetsPerSec,
                      activeConnections: metrics.activeConnections,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    // ⚠️ FIX: ThreatAlertsCardAnalyst now requires `onViewAll`
                    // (it added a "view all" link matching the admin card) —
                    // this call was missing it entirely, which is a compile
                    // error (missing required argument). Wired it to the
                    // analyst's own Reports screen, same as the admin card
                    // navigates to '/reports-admin'.
                    child: ThreatAlertsCardAnalyst(
                      threats: threats,
                      totalThreats: totalThreats,
                      onViewAll: () => Navigator.pushNamed(context, '/reports'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────
class _TopBarAnalyst extends StatelessWidget {
  final String title;
  const _TopBarAnalyst({super.key, required this.title});

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
              IconButton(
                icon: const Icon(LucideIcons.bell, size: 22),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
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