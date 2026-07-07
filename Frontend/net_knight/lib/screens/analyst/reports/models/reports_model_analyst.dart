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

  // ⚠️ FIX: some backend call sites (firewall.controller.js / NAT.controller.js)
  // call logActivity(adminId, adminName, action, target, details = "") with
  // only 4 arguments, so the description string actually lands in the
  // `target` field while `details` stays as an empty string "" (not null).
  // The old fallback chain `json['details'] ?? json['message'] ?? json['target']`
  // stops at the *first non-null* value — an empty string "" counts as
  // non-null, so it never fell through to `target`, and the Message column
  // rendered blank for every "Add Table" / "Add Chain" / static rule /
  // NAT rule log entry even though a real description existed in `target`.
  // We now pick the first *non-empty* value instead, so it correctly falls
  // through past an empty details/message to a populated target.
  static String _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v;
    }
    return '';
  }

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