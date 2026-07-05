class ThreatModel {
  final String attackName;
  final String attackSource;
  final String severity;
  final String status;
  final String date;

  ThreatModel({
    required this.attackName,
    required this.attackSource,
    required this.severity,
    required this.status,
    required this.date,
  });

  factory ThreatModel.fromJson(Map<String, dynamic> json) {
    return ThreatModel(
      attackName: json['attackName'] ?? 'Unknown',
      attackSource: json['source'] ?? json['ip'] ?? 'Unknown',
      severity: json['severity'] ?? 'Medium',
      status: json['status'] ?? 'Active',
      date: json['date'] ?? json['timestamp'] ?? '',
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

  LogModel({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.type,
    required this.message,
    this.ip = '-',
  });

  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      timestamp: json['timestamp'] ?? '',
      level: json['level'] ?? 'INFO',
      source: json['source'] ?? 'System',
      type: json['type'] ?? 'Unknown',
      message: json['message'] ?? '',
      ip: json['ip'] ?? '-',
    );
  }
}

enum ReportTab { threats, logs }