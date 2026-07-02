import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// ─── Stat Card Data ───────────────────────────────────────────
class StatDataAnalyst {
  final String label;
  final String value;
  final String trend;
  final Color color;

  const StatDataAnalyst({
    required this.label,
    required this.value,
    required this.trend,
    required this.color,
  });

  factory StatDataAnalyst.fromJson(Map<String, dynamic> json) {
    return StatDataAnalyst(
      label: json['label'] ?? '',
      value: json['value']?.toString() ?? '0',
      trend: json['trend'] ?? '— 0%',
      color: const Color(0xFF3B82F6),
    );
  }
}

// ─── System Status Data ───────────────────────────────────────
class StatusDataAnalyst {
  final String name;
  final String status;
  final Color color;

  const StatusDataAnalyst({
    required this.name,
    required this.status,
    required this.color,
  });

  factory StatusDataAnalyst.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString().toLowerCase() ?? 'offline';
    return StatusDataAnalyst(
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      color: _statusColor(status),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'online':
        return const Color(0xFF22C55E);
      case 'auto':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFF85149);
    }
  }
}

// ─── Threat Data ──────────────────────────────────────────────
class ThreatDataAnalyst {
  final String ip;
  final String type;
  final String level;
  final String confidence;
  final String time;

  const ThreatDataAnalyst({
    required this.ip,
    required this.type,
    required this.level,
    required this.confidence,
    required this.time,
  });

  factory ThreatDataAnalyst.fromJson(Map<String, dynamic> json) {
    return ThreatDataAnalyst(
      ip: json['ip'] ?? '',
      type: json['type'] ?? '',
      level: json['level'] ?? '',
      confidence: json['confidence'] ?? '',
      time: json['time'] ?? '',
    );
  }
}

// ─── Chart Series ─────────────────────────────────────────────
class ChartSeriesAnalyst {
  final Color color;
  final String label;
  final List<FlSpot> spots;

  const ChartSeriesAnalyst({
    required this.color,
    required this.label,
    required this.spots,
  });
}

// ─── Statistics Summary ───────────────────────────────────────
class StatisticsSummaryAnalyst {
  final List<StatDataAnalyst> stats;
  final List<StatusDataAnalyst> systemStatuses;
  final List<ThreatDataAnalyst> threats;
  final double cpuUsage;
  final double memoryUsage;
  final String packetsPerSec;
  final String activeConnections;
  final int totalThreats;

  const StatisticsSummaryAnalyst({
    required this.stats,
    required this.systemStatuses,
    required this.threats,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.packetsPerSec,
    required this.activeConnections,
    required this.totalThreats,
  });

  factory StatisticsSummaryAnalyst.fromJson(Map<String, dynamic> json) {
    final statsList = (json['stats'] as List? ?? [])
        .map((e) => StatDataAnalyst.fromJson(e))
        .toList();

    final statusList = (json['systemStatuses'] as List? ?? [])
        .map((e) => StatusDataAnalyst.fromJson(e))
        .toList();

    final threatList = (json['threats'] as List? ?? [])
        .map((e) => ThreatDataAnalyst.fromJson(e))
        .toList();

    return StatisticsSummaryAnalyst(
      stats: statsList,
      systemStatuses: statusList,
      threats: threatList,
      cpuUsage: (json['cpuUsage'] ?? 0).toDouble() / 100,
      memoryUsage: (json['memoryUsage'] ?? 0).toDouble() / 100,
      packetsPerSec: json['packetsPerSec']?.toString() ?? '0',
      activeConnections: json['activeConnections']?.toString() ?? '0',
      totalThreats: json['totalThreats'] ?? 0,
    );
  }
}