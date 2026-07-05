import 'package:flutter/material.dart';
import '../models/ai_rule_model.dart';

class RuleCard extends StatelessWidget {
  final AiRuleModel rule;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onToggle;

  const RuleCard({
    super.key,
    required this.rule,
    required this.onApprove,
    required this.onReject,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = rule.status != AiRuleStatus.pending;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _getBorderColor(rule.status), width: 1.5),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Rule #${rule.id}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(rule.timeAgo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF080B0F),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              rule.action,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 8),
          _label('The guide'),
          _sub(rule.guide),
          const SizedBox(height: 6),
          _label('Detected pattern'),
          _sub(rule.pattern),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: isDone
                ? _Badge(rule.status)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Btn('Approve', Colors.green, onApprove),
                      const SizedBox(width: 10),
                      _Btn('Reject', Colors.red, onReject),
                      const SizedBox(width: 10),
                      _Btn('Toggle', Colors.orange, onToggle),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor(AiRuleStatus status) {
    switch (status) {
      case AiRuleStatus.approved:
        return Colors.green;
      case AiRuleStatus.rejected:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

Widget _label(String t) => Text(
  t,
  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
);

Widget _sub(String t) => Text(
  t,
  style: const TextStyle(fontSize: 11, color: Colors.grey),
);

class _Badge extends StatelessWidget {
  final AiRuleStatus status;
  const _Badge(this.status);

  @override
  Widget build(BuildContext context) {
    final ok = status == AiRuleStatus.approved;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: (ok ? Colors.green : Colors.red).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        ok ? '✓ Approved' : '✕ Rejected',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: ok ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Btn(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
  );
}