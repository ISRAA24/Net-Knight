import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/nk_colors.dart';
import '../models/rule_model.dart';

class RuleTable extends StatefulWidget {
  const RuleTable({
    super.key,
    required this.rules,
    required this.onToggle,
    required this.onDelete,
  });

  final List<RuleModel> rules;
  final Future<void> Function(String id) onToggle;
  final void Function(String id) onDelete;

  @override
  State<RuleTable> createState() => _RuleTableState();
}

class _RuleTableState extends State<RuleTable> {
  final Set<String> _pendingToggles = {};

  late Map<String, bool> _localEnabled;

  @override
  void initState() {
    super.initState();
    _localEnabled = {
      for (final r in widget.rules) r.id: r.enabled,
    };
  }

  @override
  void didUpdateWidget(RuleTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final r in widget.rules) {
      if (!_pendingToggles.contains(r.id)) {
        _localEnabled[r.id] = r.enabled;
      }
    }
  }

  Color _actionColor(String action) {
    switch (action.toLowerCase()) {
      case 'drop':
        return const Color(0xFFEF4444);
      case 'accept':
        return const Color(0xFF22C55E);
      case 'nat':
        return const Color(0xFFF59E0B);
      default:
        return NKColors.onSurface;
    }
  }

  Future<void> _handleToggle(RuleModel rule) async {
    if (_pendingToggles.contains(rule.id)) return;

    final current = _localEnabled[rule.id] ?? rule.enabled;

    setState(() {
      _localEnabled[rule.id] = !current;
      _pendingToggles.add(rule.id);
    });

    try {
      await widget.onToggle(rule.id);
    } catch (_) {
      if (mounted) setState(() => _localEnabled[rule.id] = current);
    } finally {
      if (mounted) setState(() => _pendingToggles.remove(rule.id));
    }
  }

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
            // ─── Header ───────────────────────────────────
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  _TH('Status', flex: 2),
                  _THD(),
                  _TH('No.', flex: 1),
                  _THD(),
                  _TH('Source IP', flex: 3),
                  _THD(),
                  _TH('Destination', flex: 3),
                  _THD(),
                  _TH('Port', flex: 2),
                  _THD(),
                  _TH('Protocol', flex: 2),
                  _THD(),
                  _TH('Action', flex: 2),
                  _THD(),
                  _TH('Actions', flex: 2),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black),

            // ─── Rows ─────────────────────────────────────
            widget.rules.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No rules found.',
                        style: TextStyle(color: Colors.black45),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.rules.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.black),
                    itemBuilder: (_, i) {
                      final rule = widget.rules[i];
                      final isPending = _pendingToggles.contains(rule.id);
                      final isEnabled = _localEnabled[rule.id] ?? rule.enabled;

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _TDWidget(
                              flex: 2,
                              child: Center(
                                child: _SmallToggle(
                                  value: isEnabled,
                                  isPending: isPending,
                                  onChanged: (_) => _handleToggle(rule),
                                ),
                              ),
                            ),
                            _VD(),
                            _TD(rule.no.toString(), flex: 1),
                            _VD(),
                            _TD(rule.sourceIp, flex: 3),
                            _VD(),
                            _TD(rule.destIp, flex: 3),
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
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            _VD(),
                            _TDWidget(
                              flex: 2,
                              child: IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 16),
                                color: Colors.black,
                                onPressed: () => widget.onDelete(rule.id),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── Table Helpers ────────────────────────────────────────

class _THD extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 48, color: Colors.black);
}

class _VD extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, color: Colors.black);
}

class _TH extends StatelessWidget {
  const _TH(this.text, {required this.flex});
  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black,
            ),
          ),
        ),
      );
}

class _TD extends StatelessWidget {
  // ignore: unused_element_parameter
  const _TD(this.text, {required this.flex, this.color, this.size = 13});
  final String text;
  final int flex;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Text(
            text,
            style: TextStyle(fontSize: size, color: color ?? Colors.black),
          ),
        ),
      );
}

class _TDWidget extends StatelessWidget {
  const _TDWidget({required this.flex, required this.child});
  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: child,
        ),
      );
}

// ─── Small Toggle ─────────────────────────────────────────

class _SmallToggle extends StatelessWidget {
  const _SmallToggle({
    required this.value,
    required this.onChanged,
    this.isPending = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPending ? null : () => onChanged(!value),
      child: Opacity(
        opacity: isPending ? 0.6 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: value ? const Color(0xFF123F77) : const Color(0xFFCCCCCC),
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