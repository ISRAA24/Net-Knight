enum AiRuleStatusAnalyst { pending, approved, rejected }

class AiRuleModelAnalyst {
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
  final AiRuleStatusAnalyst status;

  const AiRuleModelAnalyst({
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
    this.status = AiRuleStatusAnalyst.pending,
  });

  // ⚠️ FIX: this model previously only read 'pattern'/'created_at', which
  // don't exist on the AIRule document at all, so "Detected pattern" always
  // rendered empty. It now reads the same real fields the admin model uses
  // (explanationDetails / mitigation_reason / evidence / ids / anomaly),
  // so the Detected Pattern section can show the same Read More/Read Less
  // content as the admin screen.
  factory AiRuleModelAnalyst.fromJson(Map<String, dynamic> json) {
    return AiRuleModelAnalyst(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      timeAgo: _timeAgoFrom(json['createdAt']?.toString()),
      action: (json['action'] ?? json['description'] ?? '').toString(),
      pattern: _buildPattern(json),
      guide: (json['explanation'] ?? json['description'] ?? '').toString(),
      description: json['description']?.toString(),
      mitigationReason:
          json['explanationDetails']?['mitigation_reason']?.toString() ??
              json['mitigation_reason']?.toString(),
      idsLabel: json['ids']?['label']?.toString(),
      anomalySeverity: json['anomaly']?['severity']?.toString(),
      explanationDetails: json['explanationDetails'] as Map<String, dynamic>?,
      evidence: json['explanationDetails']?['evidence'] as List<dynamic>? ??
          json['evidence'] as List<dynamic>?,
      isActive: json['isActive'] ?? true,
      status: _parseStatus(json['status']),
    );
  }

  static String _buildPattern(Map<String, dynamic> json) {
    final attackType = json['attackType']?.toString() ?? '';
    final confidence = json['confidence'];
    if (attackType.isEmpty) return json['description']?.toString() ?? '';
    return confidence != null ? '$attackType ($confidence% confidence)' : attackType;
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

  static AiRuleStatusAnalyst _parseStatus(dynamic s) {
    switch (s?.toString().toLowerCase()) {
      case 'approved':
      case 'auto-approved':
        return AiRuleStatusAnalyst.approved;
      case 'rejected':
        return AiRuleStatusAnalyst.rejected;
      default:
        return AiRuleStatusAnalyst.pending;
    }
  }
}

class AiRulesStatsAnalyst {
  final int pending;
  final int approved;
  final int rejected;
  final int total;

  const AiRulesStatsAnalyst({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.total,
  });

  factory AiRulesStatsAnalyst.fromRules(List<AiRuleModelAnalyst> rules) {
    return AiRulesStatsAnalyst(
      pending:
          rules.where((r) => r.status == AiRuleStatusAnalyst.pending).length,
      approved:
          rules.where((r) => r.status == AiRuleStatusAnalyst.approved).length,
      rejected:
          rules.where((r) => r.status == AiRuleStatusAnalyst.rejected).length,
      total: rules.length,
    );
  }
}