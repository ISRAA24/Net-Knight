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

  final String action;

  const ThreatData({
    required this.ip,
    required this.type,
    required this.level,
    required this.confidence,
    required this.time,
    this.action = '',
  });


  factory ThreatData.fromJson(Map<String, dynamic> json) {
    final rawLevel = (json['severity'] ?? json['level'] ?? '').toString();
    final level = rawLevel.trim().isEmpty
        ? 'Unknown'
        : rawLevel[0].toUpperCase() + rawLevel.substring(1).toLowerCase();

    return ThreatData(
      ip: json['sourceIp'] ?? json['ip'] ?? '',
      type: json['attackType'] ?? json['type'] ?? '',
      level: level,
      confidence: json['confidence'] != null
          ? '${json['confidence']}%'
          : (json['confidence']?.toString() ?? '0%'),
      time: json['createdAt'] ?? json['time'] ?? '',
      action: (json['action'] ?? '').toString(),
    );
  }
}