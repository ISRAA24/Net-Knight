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
  // Real mitigation action from the backend Threat document (Threat.js
  // now has an `action` field), used instead of a hardcoded "Block" label.
  final String action;

  const ThreatDataAnalyst({
    required this.ip,
    required this.type,
    required this.level,
    required this.confidence,
    required this.time,
    this.action = '',
  });

  // ⚠️ FIX: the backend (GET /ai/threats -> Threat model) actually returns
  // documents shaped like { sourceIp, attackType, severity, confidence,
  // createdAt, action, details } — there is no "ip"/"type"/"level"/"time"
  // field at all, so every threat used to render with blank IP/type/level/
  // time (only `action` matched, since that field name lines up with the
  // backend's new field). We now read the real field names, keeping the
  // old ones as a fallback, and capitalize severity so it matches the
  // 'Critical'/'High' comparisons used by ThreatAlertsCardAnalyst.
  //
  // ⚠️ FIX 2: previously an empty/missing severity turned into an empty
  // string, which rendered as a blank line above the IP on the Threat
  // Alerts card (e.g. the "Brute Force" entry in the screenshot had no
  // visible level at all). It now falls back to a clear 'Unknown' label
  // instead of silently disappearing, while still showing the REAL
  // backend value (Critical/High/Medium/Low) whenever it's present.
  factory ThreatDataAnalyst.fromJson(Map<String, dynamic> json) {
    final rawLevel = (json['severity'] ?? json['level'] ?? '').toString();
    final level = rawLevel.trim().isEmpty
        ? 'Unknown'
        : rawLevel[0].toUpperCase() + rawLevel.substring(1).toLowerCase();

    final rawConfidence = json['confidence'];
    final confidence = rawConfidence != null
        ? '$rawConfidence%'
        : (json['confidence']?.toString() ?? '0%');

    return ThreatDataAnalyst(
      ip: json['sourceIp']?.toString() ?? json['ip']?.toString() ?? '',
      type: json['attackType']?.toString() ?? json['type']?.toString() ?? '',
      level: level,
      confidence: confidence,
      time: json['createdAt']?.toString() ?? json['time']?.toString() ?? '',
      action: (json['action'] ?? '').toString(),
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