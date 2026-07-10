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

  static String _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v;
    }
    return '';
  }

  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      timestamp: json['date'] ?? json['timestamp'] ?? '',
      level: json['level'] ?? _deriveLevel(json['action']?.toString() ?? ''),
      source: json['userName'] ?? json['source'] ?? '',
      type: json['action'] ?? json['type'] ?? '',
      message: _firstNonEmpty([
        json['details']?.toString(),
        json['message']?.toString(),
        json['target']?.toString(),
      ]),
      ip: json['ip'] ?? '-',
    );
  }

  static String _deriveLevel(String action) {
    final a = action.toLowerCase();
    if (a.contains('delete') || a.contains('reject') || a.contains('disable')) {
      return 'WARNING';
    }
    if (a.contains('fail') || a.contains('error')) {
      return 'ERROR';
    }
    return 'INFO';
  }
}

enum ReportTab { threats, logs }