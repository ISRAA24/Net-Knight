import 'package:flutter/material.dart';
import 'package:net_knight/core/network/base_services.dart';
import 'package:net_knight/core/network/dashboard_socket_service.dart';
import '../models/stat_model.dart';

class StatService {
  Future<StatData> getDashboardStats() async {
    try {
      final response = await BaseService.dio.get('/dashboard/stats');
      final data = response.data['data'] as Map<String, dynamic>;

      return StatData(
        totalThreat: data['totalThreats']?.toString() ?? '0',
        blockedAttack: data['blockedAttacks']?.toString() ?? '0',
        activeRules: data['activeRules']?.toString() ?? '0',
        pendingApprovals: data['pendingApprovals']?.toString() ?? '0',
        trend: '↗ 0%',
        blockedTrend: '↗ 0%',
        activeTrend: '↗ 0%',
        pendingTrend: '— 0%',
      );
    } catch (e) {
      print('Error fetching stats: $e');
      return const StatData(
        totalThreat: '0',
        blockedAttack: '0',
        activeRules: '0',
        pendingApprovals: '0',
        trend: '↗ 0%',
        blockedTrend: '↗ 0%',
        activeTrend: '↗ 0%',
        pendingTrend: '— 0%',
      );
    }
  }

  Future<List<ThreatData>> getThreats() async {
    try {
      final results = await Future.wait([
        BaseService.dio.get('/ai/threats'),
        BaseService.dio.get('/ai/rules'),
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
          final threat = ThreatData.fromJson(e);
          if (e is! Map) return threat;
          final id = (e['_id'] ?? e['id'])?.toString();
          final matchedAction = id != null ? actionByThreatId[id] : null;
          if (matchedAction == null) return threat;
          return ThreatData(
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
      print('Error fetching threats: $e');
      return [];
    }
  }


  Future<List<StatusData>> getSystemStatus() async {
    return computeLiveStatuses();
  }

  // ⚠️ FIX: statistics_screen.dart calls `StatService.computeLiveStatuses()`
  // as a static method on every build (so the System Status card reflects
  // the socket's live connection/heartbeat state immediately, not just
  // once at initial load). That static method never existed — only the
  // async instance method above did — causing a compile-time error
  // (undefined_method). Mirrors
  // StatisticsServiceAnalyst.computeLiveStatuses() on the analyst side.
  static List<StatusData> computeLiveStatuses() {
    final socket = DashboardSocketService.instance;
    final alive = socket.isConnected && socket.isAgentAlive;

    const onlineColor = Color(0xFF22C55E);
    const offlineColor = Color(0xFFEF4444);
    const autoColor = Color(0xFF3B82F6);

    return [
      StatusData(
        'firewall engine',
        alive ? 'online' : 'offline',
        alive ? onlineColor : offlineColor,
      ),
      StatusData(
        'AI detection model',
        alive ? 'online' : 'offline',
        alive ? onlineColor : offlineColor,
      ),
      StatusData(
        'RL agent',
        alive ? 'Auto' : 'offline',
        alive ? autoColor : offlineColor,
      ),
      StatusData(
        'nftables controller',
        alive ? 'online' : 'offline',
        alive ? onlineColor : offlineColor,
      ),
    ];
  }
}
