class AiRuleModel {
  final String id;
  final String timeAgo;
  final String action;
  final String pattern;
  final String guide;
  final String? description;
  final String? mitigationReason;
  final String? idsLabel;
  final String? anomalySeverity;
  final Map<String, dynamic>? explanationDetails;
  final List<dynamic>? evidence;
  final bool isActive;
  AiRuleStatus status;

  AiRuleModel({
    required this.id,
    required this.timeAgo,
    required this.action,
    required this.pattern,
    required this.guide,
    this.description,
    this.mitigationReason,
    this.idsLabel,
    this.anomalySeverity,
    this.explanationDetails,
    this.evidence,
    this.isActive = true,
    this.status = AiRuleStatus.pending,
  });

  factory AiRuleModel.fromJson(Map<String, dynamic> json) {
    return AiRuleModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      timeAgo: _timeAgoFrom(json['createdAt']?.toString()),
      action: (json['action'] ?? json['description'] ?? '').toString(),
      pattern: _buildPattern(json),
      guide: (json['explanation'] ?? json['description'] ?? '').toString(),
      description: json['description']?.toString(),
      mitigationReason: json['explanationDetails']?['mitigation_reason']?.toString() ?? json['mitigation_reason']?.toString(),
      idsLabel: json['ids']?['label']?.toString(),
      anomalySeverity: json['anomaly']?['severity']?.toString(),
      explanationDetails: json['explanationDetails'] as Map<String, dynamic>?,
      evidence: json['explanationDetails']?['evidence'] as List<dynamic>? ?? json['evidence'] as List<dynamic>?,
      isActive: json['isActive'] ?? true,
      status: _parseStatus(json['status']),
    );
  }

  static String _buildPattern(Map<String, dynamic> json) {
    final attackType = json['attackType']?.toString() ?? '';
    final confidence = json['confidence'];
    if (attackType.isEmpty) return json['description']?.toString() ?? '';
    return confidence != null ? '$attackType (${(confidence * 100).toInt()}% confidence)' : attackType;
  }

  static String _timeAgoFrom(String? iso) {
    if (iso == null || iso.isEmpty) return 'just now';
    final date = DateTime.tryParse(iso);
    if (date == null) return 'just now';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static AiRuleStatus _parseStatus(dynamic s) {
    final str = s?.toString().toLowerCase() ?? '';
    if (str.contains('approved')) return AiRuleStatus.approved;
    if (str.contains('rejected')) return AiRuleStatus.rejected;
    return AiRuleStatus.pending;
  }
}

enum AiRuleStatus { pending, approved, rejected }