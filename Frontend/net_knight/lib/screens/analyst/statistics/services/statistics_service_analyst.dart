import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:net_knight/core/network/base_services.dart';
import 'package:net_knight/core/network/dashboard_socket_service.dart';
import '../models/statistics_model_analyst.dart';

class StatisticsServiceAnalyst {
  final Dio _dio = BaseService.dio;
  Future<StatisticsSummaryAnalyst> getStatistics() async {
    final results = await Future.wait([_getDashboardStats(), _getThreats()]);

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
