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
  // computeLiveStatuses below) instead of hardcoded strings.
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
      debugPrint('Error fetching dashboard stats: $e');
      return {};
    }
  }

  // ⚠️ FIX: the Threat document itself (Backend/src/models/Threat.js) has
  // no `action` field at all — the real mitigation action lives on the
  // related AIRule document (AIRule.action, linked back via
  // AIRule.threatId -> Threat._id). This previously read `json['action']`
  // straight off the /ai/threats response, which is always null/empty, so
  // the Threat Alerts card here always fell back to the hardcoded "Block"
  // label and never showed the real per-threat action (unlike the admin
  // dashboard's StatService.getThreats(), which already does this join).
  // We now fetch both '/ai/threats' and '/ai/rules' and join them
  // client-side by matching threat._id against rule.threatId, exactly
  // like the admin implementation, so both dashboards behave identically.
  Future<List<ThreatDataAnalyst>> _getThreats() async {
    try {
      final results = await Future.wait([
        _dio.get('/ai/threats'),
        _dio.get('/ai/rules'),
      ]);

      final threatsData = results[0].data['data'];
      final rulesData = results[1].data['data'];

      final actionByThreatId = <String, String>{};
      if (rulesData is List) {
        for (final rule in rulesData) {
          if (rule is! Map) continue;
          final threatId = rule['threatId'];
          final action = rule['action'];
          if (threatId != null &&
              action != null &&
              action.toString().isNotEmpty) {
            actionByThreatId[threatId.toString()] = action.toString();
          }
        }
      }

      if (threatsData is List) {
        return threatsData.map((e) {
          final threat = ThreatDataAnalyst.fromJson(e);
          if (e is! Map) return threat;
          final id = (e['_id'] ?? e['id'])?.toString();
          final matchedAction = id != null ? actionByThreatId[id] : null;
          if (matchedAction == null || matchedAction.isEmpty) return threat;
          return ThreatDataAnalyst(
            ip: threat.ip,
            type: threat.type,
            level: threat.level,
            confidence: threat.confidence,
            time: threat.time,
            action: matchedAction,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching threats: $e');
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