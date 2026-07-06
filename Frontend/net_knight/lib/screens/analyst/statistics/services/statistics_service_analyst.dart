import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:net_knight/core/network/base_services.dart';
import 'package:net_knight/core/network/dashboard_socket_service.dart';
import '../models/statistics_model_analyst.dart';

class StatisticsServiceAnalyst {
  final Dio _dio = BaseService.dio;

  // ⚠️ FIX: this used to call GET '/statistics', which does not exist
  // anywhere on the backend (server.js only mounts /api/auth, /api/users,
  // /api/staticfirewall, /api/ai, /api/dashboard, /api/notifications) —
  // every call 404'd, which is exactly why the Statistics screen showed
  // "Failed to load statistics". The admin dashboard gets the same data
  // by combining GET /dashboard/stats (counters) and GET /ai/threats
  // (threat list). System status used to be a static fallback list —
  // it's now derived from the DashboardSocketService connection (see
  // _computeLiveStatuses below) instead of hardcoded strings.
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
      systemStatuses: computeLiveStatuses(),
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

  // ⚠️ FIX: there is still no backend endpoint that returns per-component
  // system status (firewall engine / AI detection model / RL agent /
  // nftables controller are not tracked separately anywhere). Instead of
  // hardcoding all four rows as permanently "online" (static text), we
  // derive a real (if coarse) signal from DashboardSocketService: whether
  // a 'dashboard:update' with realtime metrics has arrived from the
  // Python agent within the last few seconds. All four rows move together
  // since they currently share the same single signal — this is a
  // meaningful improvement over a fixed string, but it is NOT a substitute
  // for a backend endpoint that reports each component's health
  // individually. This is public (not private) so the screen can recompute
  // it live on every socket update, not just once at initial load.
  static List<StatusDataAnalyst> computeLiveStatuses() {
    final socket = DashboardSocketService.instance;
    final alive = socket.isConnected && socket.isAgentAlive;

    const onlineColor = Color(0xFF22C55E);
    const offlineColor = Color(0xFFF85149);
    const autoColor = Color(0xFF3B82F6);

    return [
      StatusDataAnalyst(
        name: 'firewall engine',
        status: alive ? 'online' : 'offline',
        color: alive ? onlineColor : offlineColor,
      ),
      StatusDataAnalyst(
        name: 'AI detection model',
        status: alive ? 'online' : 'offline',
        color: alive ? onlineColor : offlineColor,
      ),
      StatusDataAnalyst(
        name: 'RL agent',
        status: alive ? 'Auto' : 'offline',
        color: alive ? autoColor : offlineColor,
      ),
      StatusDataAnalyst(
        name: 'nftables controller',
        status: alive ? 'online' : 'offline',
        color: alive ? onlineColor : offlineColor,
      ),
    ];
  }
}