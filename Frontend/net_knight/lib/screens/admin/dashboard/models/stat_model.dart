import 'package:flutter/material.dart';

class StatData {
  final String totalThreat;
  final String blockedAttack;
  final String activeRules;
  final String pendingApprovals;
  final String trend;
  final String blockedTrend;
  final String activeTrend;
  final String pendingTrend;

  const StatData({
    required this.totalThreat,
    required this.blockedAttack,
    required this.activeRules,
    required this.pendingApprovals,
    required this.trend,
    required this.blockedTrend,
    required this.activeTrend,
    required this.pendingTrend,
  });
}

class StatusData {
  final String name;
  final String status;
  final Color color;

  const StatusData(this.name, this.status, this.color);

  factory StatusData.fromJson(Map<String, dynamic> json) {
    return StatusData(
      json['name'] ?? '',
      json['status'] ?? '',
      _parseColor(json['color']),
    );
  }

  static Color _parseColor(String? color) {
    switch (color?.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'amber':
        return Colors.amber;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class ThreatData {
  final String ip;
  final String type;
  final String level;
  final String confidence;
  final String time;

  const ThreatData({
    required this.ip,
    required this.type,
    required this.level,
    required this.confidence,
    required this.time,
  });

  factory ThreatData.fromJson(Map<String, dynamic> json) {
    return ThreatData(
      ip: json['ip'] ?? '',
      type: json['type'] ?? '',
      level: json['level'] ?? '',
      confidence: json['confidence']?.toString() ?? '0%',
      time: json['time'] ?? '',
    );
  }
}