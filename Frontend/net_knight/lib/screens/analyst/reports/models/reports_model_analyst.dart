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
      attackName: json['attackType'] ?? json['attackName'] ?? 'Unknown',
      attackSource: json['sourceIp'] ?? json['source'] ?? json['ip'] ?? 'Unknown',
      severity: json['severity'] ?? 'Medium',
      status: json['status'] ?? 'Active',
      date: json['createdAt'] ?? json['date'] ?? json['timestamp'] ?? '',
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

  // Backend (audit.controller.js -> getAuditLogs) actually returns:
  // { no, date, userName, action, target, details } — there is no "level"
  // field, so we derive one from the action text instead of always
  // defaulting to "INFO".
  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      timestamp: json['date'] ?? json['timestamp'] ?? '',
      level: json['level'] ?? _deriveLevel(json['action']?.toString() ?? ''),
      source: json['userName'] ?? json['source'] ?? 'System',
      type: json['action'] ?? json['type'] ?? 'Unknown',
      message: json['details'] ?? json['message'] ?? json['target'] ?? '',
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