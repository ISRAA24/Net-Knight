import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:net_knight/screens/admin/rule_management/models/rule_management_model.dart';

class NatTable extends StatelessWidget {
  final List<NatRuleModel> natRules;
  final Function(String id, bool enabled) onToggle;
  final Function(String id) onDelete;

  const NatTable({
    super.key,
    required this.natRules,
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
                  _TH('Source IP', flex: 3),
                  _TH('Interface', flex: 2),
                  _TH('Translated IP/Dest IP', flex: 3),
                  _TH('Ext Port', flex: 2),
                  _TH('Int Port', flex: 2),
                  _TH('NAT Type', flex: 2),
                  _TH('Created', flex: 2),
                  _TH('Actions', flex: 2),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black),
            // ⚠️ FIX: no longer wrapped in Expanded — the table now sizes
            // itself to the number of NAT rules (grows/shrinks with data)
            // since the parent screen puts this inside a scroll view.
            natRules.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No NAT rules found')),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: natRules.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.black),
                    itemBuilder: (_, i) {
                      final rule = natRules[i];
                      return _NatRow(
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

class _NatRow extends StatelessWidget {
  final NatRuleModel rule;
  final Function(String id, bool enabled) onToggle;
  final Function(String id) onDelete;

  const _NatRow({
    required this.rule,
    required this.onToggle,
    required this.onDelete,
  });
  String _getDisplayIp(NatRuleModel rule) {
    final type = rule.natType.toLowerCase();
    if (type == 'destination' || type == 'dnat') {
      return rule.destIp.isEmpty ? '—' : rule.destIp;
    } else if (type == 'source' || type == 'snat' || type == 'source nat') {
      return rule.newSourceIp.isEmpty ? '—' : rule.newSourceIp;
    }
    return '—'; // في حالة masquerade أو أي نوع آخر
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TDWidget(
            flex: 2,
            child: Center(
              child: _SmallToggle(
                value: rule.enabled,
                onChanged: (v) => onToggle(rule.id, v),
              ),
            ),
          ),
          _VD(),
          _TD(rule.sourceIp, flex: 3),
          _VD(),
          _TD(rule.interfaceName, flex: 2),
          _VD(),
          _TD(rule.destIp, flex: 3),
          _VD(),
          _TD(rule.extPort, flex: 2),
          _VD(),
          _TD(rule.intPort, flex: 2),
          _VD(),
          _TDWidget(
            flex: 2,
            child: Text(
              rule.natType,
              style: TextStyle(
                color: _natTypeColor(rule.natType),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _VD(),
          _TD(rule.created, flex: 2),
          _VD(),
          _TDWidget(
            flex: 2,
            child: IconButton(
              icon: const Icon(LucideIcons.trash2, size: 16),
              onPressed: () => onDelete(rule.id),
            ),
          ),
        ],
      ),
    );
  }

  Color _natTypeColor(String type) {
    final t = type.toLowerCase();
    if (t == 'masquerade') return Colors.green;
    if (t == 'source') return Colors.blue;
    return Colors.orange;
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
  final ValueChanged<bool> onChanged;

  const _SmallToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // ⚠️ FIX: previously this was just a bare GestureDetector, and
    // GestureDetector alone does NOT change the mouse cursor on Flutter
    // Web/Desktop (unlike InkWell, which sets a click cursor automatically).
    // So hovering over the toggle kept showing the default arrow instead of
    // a pointer/hand, even though tapping it worked fine. Wrapping it in a
    // MouseRegion with an explicit click cursor fixes that.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!value),
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