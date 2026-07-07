import 'package:flutter/material.dart';
import '../models/ai_rule_model_analyst.dart';

const _kRuleBg = Color(0xFF080B0F);
const _kActionTxt = Color(0xFF60A5FA);
const _kGreen = Color(0xFF22C55E);
const _kRed = Color(0xFFF85149);
const _kBlue = Color(0xFF3B82F6);
const _kOnSurface = Color(0xFF1D242B);

class RuleCardAnalyst extends StatelessWidget {
  const RuleCardAnalyst({super.key, required this.rule});

  final AiRuleModelAnalyst rule;

  Color get _borderColor => switch (rule.status) {
        AiRuleStatusAnalyst.approved => _kGreen,
        AiRuleStatusAnalyst.rejected => _kRed,
        AiRuleStatusAnalyst.pending => _kBlue,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rule ID
          Text(
            'Rule #${rule.id}',
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
              color: _kOnSurface,
            ),
          ),
          const SizedBox(height: 1),
          // Time
          Text(
            rule.timeAgo,
            style: const TextStyle(
              fontSize: 12,
              color: Color.fromARGB(183, 0, 0, 0),
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 8),

          // Action command box
          // ⚠️ FIX: now shows the action AND the description underneath it
          // (matching the admin's RuleCard: action "A3_PERM_BLOCK" +
          // description "[CRITICAL] DoS detected with 99.0% IDS
          // confidence. Mitigation applied: A3_PERM_BLOCK."), instead of
          // only the raw action with nothing else in the box.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 10),
            decoration: BoxDecoration(
              color: _kRuleBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(
                  rule.action,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 15,
                    color: _kActionTxt,
                  ),
                ),
                if ((rule.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    rule.description!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          _label('The guide'),
          const SizedBox(height: 1),
          _sub(rule.guide),
          const SizedBox(height: 8),

          // ⚠️ FIX: previously this just showed the raw (mostly empty)
          // `rule.pattern` string. Now it mirrors the admin screen's
          // Detected Pattern section: starts with the mitigation reason,
          // and has a "Read More Details" / "Read Less" toggle that reveals
          // analyst notes, evidence, IDS label, and anomaly severity.
          _label('Detected pattern'),
          const SizedBox(height: 4),
          _DetectedPatternSectionAnalyst(rule: rule),
        ],
      ),
    );
  }

  static Widget _label(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 15,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
          color: _kOnSurface,
        ),
      );

  static Widget _sub(String t) => Text(
        t,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 11,
          color: Color.fromARGB(161, 0, 0, 0),
        ),
      );
}

class _DetectedPatternSectionAnalyst extends StatefulWidget {
  const _DetectedPatternSectionAnalyst({required this.rule});

  final AiRuleModelAnalyst rule;

  @override
  State<_DetectedPatternSectionAnalyst> createState() =>
      _DetectedPatternSectionAnalystState();
}

class _DetectedPatternSectionAnalystState
    extends State<_DetectedPatternSectionAnalyst> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final details = widget.rule.explanationDetails;
    final mitigation = details?['mitigation_reason']?.toString() ??
        widget.rule.mitigationReason ??
        widget.rule.description ??
        'No mitigation details available';
    final analystNotes = details?['analyst_notes']?.toString() ?? '';
    final evidence =
        (details?['evidence'] as List?) ?? widget.rule.evidence ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // يبدأ مباشرة بـ mitigation_reason زي شاشة الأدمن
        Text(
          mitigation,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11,
            color: Color.fromARGB(161, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _expanded ? 'Read Less' : 'Read More Details',
                style: const TextStyle(
                  color: _kBlue,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: _kBlue,
                size: 18,
              ),
            ],
          ),
        ),

        if (_expanded) ...[
          const SizedBox(height: 12),
          if (analystNotes.isNotEmpty)
            _DetailItemAnalyst('Analyst Notes', analystNotes),

          const Divider(height: 20),

          const Text(
            'Evidence:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _kOnSurface,
            ),
          ),
          ...evidence.map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '• ${e['feature']}: ${e['value']} → ${e['reason']}',
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
          ),

          if (widget.rule.idsLabel != null)
            _DetailItemAnalyst('IDS Label', widget.rule.idsLabel!),
          if (widget.rule.anomalySeverity != null)
            _DetailItemAnalyst('Severity', widget.rule.anomalySeverity!),
        ],
      ],
    );
  }
}

class _DetailItemAnalyst extends StatelessWidget {
  const _DetailItemAnalyst(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: _kOnSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color.fromARGB(161, 0, 0, 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}