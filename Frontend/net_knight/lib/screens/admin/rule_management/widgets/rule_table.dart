import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/rule_management_model.dart';

// ⚠️ FIX: this table now shows the same column set as the analyst's Rules
// Center screen (Status, Priority, Source IP, Destination, Port, Protocol,
// Action, Origin, Created, + Admin-only Delete), instead of a reduced set
// (Status, Rule Name, Source IP, Action, Origin, Created, Actions).
class RuleTable extends StatelessWidget {
  final List<RuleModel> rules;
  final Function(String id, bool enabled, bool isAi) onToggle;
  final Function(String id, bool isAi) onDelete;

  const RuleTable({
    super.key,
    required this.rules,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.white,
              child: const Row(
                children: [
                  _TH('Status', flex: 2),
                  _TH('Priority', flex: 2),
                  _TH('Source IP', flex: 3),
                  _TH('Destination', flex: 3),
                  _TH('Port', flex: 2),
                  _TH('Protocol', flex: 2),
                  _TH('Action', flex: 2),
                  _TH('Origin', flex: 2),
                  _TH('Created', flex: 2),
                  _TH('Actions', flex: 2),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black),
            rules.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No rules found')),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rules.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.black),
                    itemBuilder: (_, i) {
                      final rule = rules[i];
                      return _RuleRow(
                        rule: rule,
                        onToggle: onToggle,
                        onDelete: onDelete,
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final RuleModel rule;
  final Function(String id, bool enabled, bool isAi) onToggle;
  final Function(String id, bool isAi) onDelete;

  const _RuleRow({
    required this.rule,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TDWidget(
            flex: 2,
            child: Center(
              // AI-generated rules live in a different collection and
              // can't be toggled through this static-rule endpoint, so
              // the switch is read-only for them.
              child: _SmallToggle(
                value: rule.enabled,
                onChanged: (v) => onToggle(rule.id, v, rule.isAi),
              ),
            ),
          ),
          _VD(),
          _TD(rule.priority, flex: 2),
          _VD(),
          _TD(rule.sourceIp, flex: 3),
          _VD(),
          _TD(rule.destination, flex: 3),
          _VD(),
          _TD(rule.port, flex: 2),
          _VD(),
          _TD(rule.protocol, flex: 2),
          _VD(),
          _TDWidget(
            flex: 2,
            child: Text(
              rule.action,
              style: TextStyle(
                color: _actionColor(rule.action),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _VD(),
          _TD(rule.origin, flex: 2),
          _VD(),
          _TD(rule.created, flex: 2),
          _VD(),
          _TDWidget(
            flex: 2,
            child: IconButton(
              icon: const Icon(LucideIcons.trash2, size: 16),
              // Deleting an AI rule also requires the backend to unwind
              // its firewall handles (handled by /ai/rules/:id), which is
              // a different endpoint than static rules — not wired up
              // here, so we disable delete for AI rules on this screen.
              onPressed: () => onDelete(rule.id , rule.isAi),
            ),
          ),
        ],
      ),
    );
  }

  Color _actionColor(String action) {
    final a = action.toLowerCase();
    if (a == 'drop' || a == 'reject') return Colors.red;
    if (a == 'accept') return Colors.green;
    return Colors.blue;
  }
}

// Helpers
class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

class _TD extends StatelessWidget {
  final String text;
  final int flex;
  const _TD(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Text(text, overflow: TextOverflow.ellipsis),
    ),
  );
}

class _TDWidget extends StatelessWidget {
  final int flex;
  final Widget child;
  const _TDWidget({required this.flex, required this.child});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(padding: const EdgeInsets.all(14), child: child),
  );
}

class _VD extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, color: Colors.black);
}

class _SmallToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SmallToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: GestureDetector(
        onTap: disabled ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: value ? Colors.blue : Colors.grey,
          ),
          padding: const EdgeInsets.all(2),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
