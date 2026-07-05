class AiRuleModel {
  final String id;
  final String timeAgo;
  final String action;
  final String pattern;
  final String guide;
  AiRuleStatus status;

  AiRuleModel({
    required this.id,
    required this.timeAgo,
    required this.action,
    required this.pattern,
    required this.guide,
    this.status = AiRuleStatus.pending,
  });

  factory AiRuleModel.fromJson(Map<String, dynamic> json) {
    return AiRuleModel(
      id: json['id'] ?? '',
      timeAgo: json['timeAgo'] ?? '',
      action: json['action'] ?? '',
      pattern: json['pattern'] ?? '',
      guide: json['guide'] ?? '',
      status: _parseStatus(json['status']),
    );
  }

  static AiRuleStatus _parseStatus(String? s) {
    switch (s?.toLowerCase()) {
      case 'approved':
        return AiRuleStatus.approved;
      case 'rejected':
        return AiRuleStatus.rejected;
      default:
        return AiRuleStatus.pending;
    }
  }
}

enum AiRuleStatus { pending, approved, rejected }