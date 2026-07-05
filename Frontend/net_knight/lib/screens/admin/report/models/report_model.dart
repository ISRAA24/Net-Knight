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
      attackName: json['attackName'] ?? '',
      attackSource: json['attackSource'] ?? '',
      severity: json['severity'] ?? '',
      status: json['status'] ?? '',
      date: json['date'] ?? '',
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

  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      timestamp: json['timestamp'] ?? '',
      level: json['level'] ?? '',
      source: json['source'] ?? '',
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      ip: json['ip'] ?? '-',
    );
  }
}

enum ReportTab { threats, logs }