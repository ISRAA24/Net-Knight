class ThreatModel {
  final String attackName;
  final String attackSource;
  final String severity;
  final String status;
  final String date;

  const ThreatModel({
    required this.attackName,
    required this.attackSource,
    required this.severity,
    required this.status,
    required this.date,
  });

  factory ThreatModel.fromJson(Map<String, dynamic> json) {
    return ThreatModel(
      attackName: json['attackType'] ?? json['attackName'] ?? '',
      attackSource: json['sourceIp'] ?? json['attackSource'] ?? '',
      severity: json['severity'] ?? '',
      status: json['status'] ?? '',
      date: json['createdAt'] ?? json['date'] ?? '',
    );
  }
}

class LogModel {
  final String timestamp;
  final String level;
  final String source;
  final String type;
  final String message;
  final String ip;

  const LogModel({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.type,
    required this.message,
    required this.ip,
  });

  // Backend (audit.controller.js -> getAuditLogs) actually returns:
  // { no, date, userName, action, target, details }
  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      timestamp: json['date'] ?? json['timestamp'] ?? '',
      level: json['level'] ?? 'INFO',
      source: json['userName'] ?? json['source'] ?? '',
      type: json['action'] ?? json['type'] ?? '',
      message: json['details'] ?? json['message'] ?? json['target'] ?? '',
      ip: json['ip'] ?? '-',
    );
  }
}

enum ReportTab { threats, logs }