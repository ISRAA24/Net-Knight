class AiRuleModel {
  final String id;
  final String timeAgo;
  final String action;
  final String pattern;
  final String guide;
  final bool isActive;
  AiRuleStatus status;

  AiRuleModel({
    required this.id,
    required this.timeAgo,
    required this.action,
    required this.pattern,
    required this.guide,
    this.isActive = true,
    this.status = AiRuleStatus.pending,
  });

  // ⚠️ FIX: كان بيقرأ json['id'] بس، لكن الباك (Mongoose) بيرجع الـ ID تحت
  // مفتاح `_id`. النتيجة إن rule.id كان دايمًا فاضي وكل نداءات
  // approve/reject/toggle/delete كانت بتفشل لأنها بتنادي على
  // `/ai/rules//review` (id فاضي). كمان الحقول timeAgo/pattern/guide
  // مكنتش موجودة أصلاً في الـ response بتاع الباك (AIRule model فيه
  // createdAt/attackType/description/explanation مش timeAgo/pattern/guide)
  // فكانت بتفضل فاضية على الشاشة.
  factory AiRuleModel.fromJson(Map<String, dynamic> json) {
    return AiRuleModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      timeAgo: _timeAgoFrom(json['createdAt']?.toString()),
      action: (json['action'] ?? '').toString(),
      pattern: _buildPattern(json),
      guide: (json['explanation'] ?? json['description'] ?? '').toString(),
      isActive: json['isActive'] ?? true,
      status: _parseStatus(json['status']),
    );
  }

  static String _buildPattern(Map<String, dynamic> json) {
    final description = json['description']?.toString() ?? '';
    if (description.isNotEmpty) return description;
    final attackType = json['attackType']?.toString() ?? '';
    final confidence = json['confidence'];
    if (attackType.isEmpty) return '';
    return confidence != null ? '$attackType ($confidence% confidence)' : attackType;
  }

  static String _timeAgoFrom(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ⚠️ FIX: الباك بيرجع status = 'auto-approved' كمان (مش 'approved' بس).
  // النسخة القديمة كانت بتحط 'auto-approved' في الـ default (pending)
  // فالرولز اللي اتعملها approve أوتوماتيك كانت بتفضل ظاهرة كـ pending.
  static AiRuleStatus _parseStatus(dynamic s) {
    switch (s?.toString().toLowerCase()) {
      case 'approved':
      case 'auto-approved':
        return AiRuleStatus.approved;
      case 'rejected':
        return AiRuleStatus.rejected;
      default:
        return AiRuleStatus.pending;
    }
  }
}

enum AiRuleStatus { pending, approved, rejected }