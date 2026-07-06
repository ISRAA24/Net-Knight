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
          // ⚠️ FIX: now also shows the description underneath the action
          // (matching the admin screen and the reference sample), instead
          // of the action alone.
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
                      fontSize: 11.5,
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
          const SizedBox(height: 6),

          _label('Detected pattern'),
          const SizedBox(height: 2),
          _sub(rule.pattern),
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
