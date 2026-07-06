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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(rule.status), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rule #${rule.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(rule.timeAgo, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),

          // ⚠️ FIX: the black box now shows the action AND the description
          // underneath it (matching the reference sample: action
          // "A2_TEMP_BLOCK" + description "Applying a temporary block on
          // 192.168.1.104 for 60 minutes"), instead of only the raw action.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF080B0F), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                Text(
                  rule.action,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.blue, fontWeight: FontWeight.w500),
                ),
                if ((rule.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    rule.description!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          _label('The guide'),
          _sub(rule.guide),
          const SizedBox(height: 16),

          // Detected Pattern - يبدأ بـ mitigation_reason (بدون الـ summary)
          _label('Detected Pattern'),
          const SizedBox(height: 8),
          _DetectedPatternSection(rule: rule),

          const SizedBox(height: 20),

          if (!isDone)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(onPressed: onApprove, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Approve')),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: onReject, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Reject')),
              ],
            ),
        ],
      ),
    );
  }

  Color _getBorderColor(AiRuleStatus status) {
    switch (status) {
      case AiRuleStatus.approved: return Colors.green;
      case AiRuleStatus.rejected: return Colors.red;
      default: return Colors.blue;
    }
  }
}

Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600));
Widget _sub(String t) => Text(t, style: const TextStyle(fontSize: 13, color: Colors.grey));

class _DetectedPatternSection extends StatefulWidget {
  final AiRuleModel rule;
  const _DetectedPatternSection({required this.rule});

  @override
  State<_DetectedPatternSection> createState() => _DetectedPatternSectionState();
}

class _DetectedPatternSectionState extends State<_DetectedPatternSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final details = widget.rule.explanationDetails;
    // ⚠️ REMOVED: the `summary` field used to be shown here as an extra line
    // above the mitigation reason — it duplicated the black action box /
    // "The guide" text, so it's no longer rendered. Everything else in this
    // section (mitigation reason, analyst notes, evidence, IDS/anomaly
    // details) stays exactly as before.
    final mitigation = details?['mitigation_reason']?.toString() ?? widget.rule.mitigationReason ?? widget.rule.description ?? 'No mitigation details available';
    final analystNotes = details?['analyst_notes']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // يبدأ مباشرة بـ mitigation_reason
        Text(mitigation, style: const TextStyle(fontSize: 13, color: Colors.grey)),

        const SizedBox(height: 8),

        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_expanded ? 'Read Less' : 'Read More Details', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.blue, size: 18),
            ],
          ),
        ),

        if (_expanded) ...[
          const SizedBox(height: 12),
          if (analystNotes.isNotEmpty) _DetailItem('Analyst Notes', analystNotes),

          const Divider(height: 20),

          const Text('Evidence:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ... (details?['evidence'] as List? ?? []).map((e) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('• ${e['feature']}: ${e['value']} → ${e['reason']}', style: const TextStyle(fontSize: 12.5)),
          )),

          if (widget.rule.idsLabel != null) _DetailItem('IDS Label', widget.rule.idsLabel!),
          if (widget.rule.anomalySeverity != null) _DetailItem('Severity', widget.rule.anomalySeverity!),
        ],
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label + ':', style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.grey))),
        ],
      ),
    );
  }
}
