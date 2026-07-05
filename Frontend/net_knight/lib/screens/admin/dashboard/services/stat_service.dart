import 'package:net_knight/core/network/base_services.dart';
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
      // NOTE: '/dashboard/threats' does not exist on the backend.
      // Threats actually live under '/ai/threats'.
      final response = await BaseService.dio.get('/ai/threats');
      final data = response.data['data'];
      if (data is List) {
        return data.map((e) => ThreatData.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching threats: $e');
      return [];
    }
  }

  // NOTE: There is currently NO backend endpoint that returns system
  // status (firewall engine / AI detection model / RL agent / nftables
  // controller). This needs to be added server-side first — until then
  // this will always fail and callers should rely on fallback data.
  Future<List<StatusData>> getSystemStatus() async {
    try {
      final response = await BaseService.dio.get('/dashboard/status');
      if (response.data is List) {
        return (response.data as List).map((e) => StatusData.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching system status: $e');
      return [];
    }
  }
}