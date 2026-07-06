enum AiRuleStatusAnalyst { pending, approved, rejected }

class AiRuleModelAnalyst {
  final String id;
  final String timeAgo;
  final String action;
  final String pattern;
  final String guide;
  // ⚠️ ADDED: the human-readable description (e.g. "Applying a temporary
  // block on 192.168.1.104 for 60 minutes"), shown under the action inside
  // the black box on the rule card — matching the admin screen.
  final String? description;
  final AiRuleStatusAnalyst status;

  const AiRuleModelAnalyst({
    required this.id,
    required this.timeAgo,
    required this.action,
    required this.pattern,
    required this.guide,
    this.description,
    this.status = AiRuleStatusAnalyst.pending,
  });

  factory AiRuleModelAnalyst.fromJson(Map<String, dynamic> json) {
    return AiRuleModelAnalyst(
      id: json['_id'] ?? json['id'] ?? '',
      timeAgo: json['timeAgo'] ?? json['created_at'] ?? '',
      action: json['action'] ?? '',
      pattern: json['pattern'] ?? '',
      guide: json['guide'] ?? json['explanation'] ?? '',
      description: json['description']?.toString(),
      status: _parseStatus(json['status']),
    );
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
