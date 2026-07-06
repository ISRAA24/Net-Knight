import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/statistics_model_analyst.dart';

class StatisticsServiceAnalyst {
  final Dio _dio = BaseService.dio;

  // ⚠️ FIX: this used to call GET '/statistics', which does not exist
  // anywhere on the backend (server.js only mounts /api/auth, /api/users,
  // /api/staticfirewall, /api/ai, /api/dashboard, /api/notifications) —
  // every call 404'd, which is exactly why the Statistics screen showed
  // "Failed to load statistics". The admin dashboard gets the same data
  // by combining GET /dashboard/stats (counters) and GET /ai/threats
  // (threat list), plus a static fallback for system status and realtime
  // metrics coming from the Socket.IO connection (handled already in
  // StatisticsScreenAnalyst via DashboardSocketService). We now do the
  // same here instead of hitting a route that was never implemented.
  Future<StatisticsSummaryAnalyst> getStatistics() async {
    final results = await Future.wait([
      _getDashboardStats(),
      _getThreats(),
    ]);

    final statsMap = results[0] as Map<String, dynamic>;
    final threats = results[1] as List<ThreatDataAnalyst>;

    final totalThreats = _asInt(statsMap['totalThreats']);

    final stats = <StatDataAnalyst>[
      StatDataAnalyst(
        label: 'Total Threat',
        value: totalThreats.toString(),
        trend: '↗ 0%',
        color: const Color(0xFF3B82F6),
      ),
      StatDataAnalyst(
        label: 'Blocked Attack',
        value: _asInt(statsMap['blockedAttacks']).toString(),
        trend: '↗ 0%',
        color: const Color(0xFFF59E0B),
      ),
      StatDataAnalyst(
        label: 'Active Rules',
        value: _asInt(statsMap['activeRules']).toString(),
        trend: '↗ 0%',
        color: const Color(0xFF22C55E),
      ),
      StatDataAnalyst(
        label: 'Pending Approvals',
        value: _asInt(statsMap['pendingApprovals']).toString(),
        trend: '— 0%',
        color: Colors.purpleAccent,
      ),
    ];

    return StatisticsSummaryAnalyst(
      stats: stats,
      systemStatuses: _fallbackStatuses,
      threats: threats,
      // Realtime values (cpu/memory/packets/connections) are provided by
      // DashboardSocketService in the screen itself, so we only need safe
      // defaults here for the initial HTTP-based load.
      cpuUsage: 0,
      memoryUsage: 0,
      packetsPerSec: '0',
      activeConnections: '0',
      totalThreats: totalThreats,
    );
  }

  Future<Map<String, dynamic>> _getDashboardStats() async {
    try {
      final response = await _dio.get('/dashboard/stats');
      final data = response.data['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return {};
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return {};
    }
  }

  Future<List<ThreatDataAnalyst>> _getThreats() async {
    try {
      final response = await _dio.get('/ai/threats');
      final data = response.data['data'];
      if (data is List) {
        return data.map((e) => ThreatDataAnalyst.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching threats: $e');
      return [];
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // Same static fallback used on the admin dashboard (StatService) —
  // there is currently no backend endpoint for live system-status rows.
  static final List<StatusDataAnalyst> _fallbackStatuses = [
    const StatusDataAnalyst(
      name: 'firewall engine',
      status: 'online',
      color: Color(0xFF22C55E),
    ),
    const StatusDataAnalyst(
      name: 'AI detection model',
      status: 'online',
      color: Color(0xFF22C55E),
    ),
    const StatusDataAnalyst(
      name: 'RL agent',
      status: 'Auto',
      color: Color(0xFF3B82F6),
    ),
    const StatusDataAnalyst(
      name: 'nftables controller',
      status: 'online',
      color: Color(0xFF22C55E),
    ),
  ];
}