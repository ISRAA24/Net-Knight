import 'package:net_knight/core/network/base_services.dart';
import '../models/stat_model.dart';

class StatService {
  Future<StatData> getDashboardStats() async {
    try {
      final response = await BaseService.dio.get('/dashboard/stats');
      final data = response.data as Map<String, dynamic>;

      return StatData(
        totalThreat: data['totalThreat']?.toString() ?? '0',
        blockedAttack: data['blockedAttack']?.toString() ?? '0',
        activeRules: data['activeRules']?.toString() ?? '0',
        pendingApprovals: data['pendingApprovals']?.toString() ?? '0',
        trend: data['trend']?.toString() ?? '↗ 0%',
        blockedTrend: data['blockedTrend']?.toString() ?? '↗ 0%',
        activeTrend: data['activeTrend']?.toString() ?? '↗ 0%',
        pendingTrend: data['pendingTrend']?.toString() ?? '— 0%',
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
      final response = await BaseService.dio.get('/dashboard/threats');
      if (response.data is List) {
        return (response.data as List).map((e) => ThreatData.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching threats: $e');
      return [];
    }
  }

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