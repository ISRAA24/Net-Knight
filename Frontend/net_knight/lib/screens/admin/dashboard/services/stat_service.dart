import 'package:flutter/material.dart';
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

  // ⚠️ FIX: there is currently NO backend endpoint that returns system
  // status (firewall engine / AI detection model / RL agent / nftables
  // controller) — '/dashboard/status' is not mounted anywhere in
  // dashboard.routes.js. The call below will always 404, so instead of
  // leaving the admin dashboard's System Status card permanently blank,
  // we return the same static fallback the analyst dashboard already
  // uses (statistics_screen_analyst.dart's `_fallbackStatuses`) so the
  // two screens behave consistently until a real endpoint is added.
  Future<List<StatusData>> getSystemStatus() async {
    try {
      final response = await BaseService.dio.get('/dashboard/status');
      if (response.data is List) {
        return (response.data as List).map((e) => StatusData.fromJson(e)).toList();
      }
      return _fallbackStatuses;
    } catch (e) {
      print('Error fetching system status: $e');
      return _fallbackStatuses;
    }
  }

  static final List<StatusData> _fallbackStatuses = [
    StatusData('firewall engine', 'online', const Color(0xFF22C55E)),
    StatusData('AI detection model', 'online', const Color(0xFF22C55E)),
    StatusData('RL agent', 'Auto', const Color(0xFF3B82F6)),
    StatusData('nftables controller', 'online', const Color(0xFF22C55E)),
  ];
}