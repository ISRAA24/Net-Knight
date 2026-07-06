import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:net_knight/main.dart';
import 'package:net_knight/screens/admin/dashboard/widgets/sidebar.dart';
import 'package:provider/provider.dart';

import 'models/ai_rule_model.dart';
import 'services/ai_rule_service.dart';
import 'widgets/rule_card.dart';
import 'widgets/stats_row.dart';

class AiGeneratedRulesScreenAdmin extends StatefulWidget {
  const AiGeneratedRulesScreenAdmin({super.key});

  @override
  State<AiGeneratedRulesScreenAdmin> createState() =>
      _AiGeneratedRulesScreenAdminState();
}

class _AiGeneratedRulesScreenAdminState
    extends State<AiGeneratedRulesScreenAdmin> {
  final _service = AiRuleService();
  List<AiRuleModel> _rules = [];
  bool _isLoading = true;
  bool _autoApprove = false;
  bool _autoApproveLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRules();
    _loadAutoApprove();
  }

  Future<void> _loadRules() async {
    setState(() => _isLoading = true);
    try {
      _rules = await _service.getAiRules();
    } catch (e) {
      print('Error loading AI rules: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAutoApprove() async {
    final value = await _service.getAutoApprove();
    if (mounted) setState(() => _autoApprove = value);
  }

  Future<void> _approveRule(String id) async {
    final success = await _service.approveRule(id);
    if (success) {
      _loadRules();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to approve rule'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRule(String id) async {
    final success = await _service.rejectRule(id);
    if (success) _loadRules();
  }

  Future<void> _toggleRule(String id) async {
    final success = await _service.toggleRule(id);
    if (success) _loadRules();
  }

  Future<void> _toggleAutoApprove(bool? newValue) async {
    if (_autoApproveLoading || newValue == null) return;
    setState(() {
      _autoApprove = newValue;
      _autoApproveLoading = true;
    });
    try {
      final saved = await _service.setAutoApprove(newValue);
      if (mounted) setState(() => _autoApprove = saved);
    } catch (e) {
      if (mounted) {
        setState(() => _autoApprove = !newValue);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update auto-approve setting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _autoApproveLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TopBar(title: 'AI Generated Rules'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatsRow(
                          autoApprove: _autoApprove,
                          onToggleAuto: () => _toggleAutoApprove(!_autoApprove),
                          rules: _rules,
                        ),
                        const SizedBox(height: 20),

                        // ⚠️ ADDED: header row with "AI Generated Rules
                        // Review" / "Rules awaiting approval: N" on the left
                        // and the "Automatic Approval" checkbox on the right,
                        // matching the reference screenshot. The checkbox is
                        // wired to GET/PUT /ai/settings/auto-approve.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Generated Rules Review',
                                  style: GoogleFonts.rajdhani(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: const Color(0xFF1D242B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Rules awaiting approval: '
                                  '${_rules.where((r) => r.status == AiRuleStatus.pending).length}',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Color.fromARGB(168, 0, 0, 0),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: _autoApproveLoading
                                  ? null
                                  : () => _toggleAutoApprove(!_autoApprove),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: _autoApproveLoading
                                          ? const Padding(
                                              padding: EdgeInsets.all(2),
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Checkbox(
                                              value: _autoApprove,
                                              onChanged: _toggleAutoApprove,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Automatic Approval',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1D242B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _RulesSection(
                          rules: _rules,
                          isLoading: _isLoading,
                          autoApprove: _autoApprove,
                          onApprove: _approveRule,
                          onReject: _rejectRule,
                          onToggle: _toggleRule,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.rajdhani(fontSize: 26, fontWeight: FontWeight.w500)),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.bell, size: 22),
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _RulesSection extends StatelessWidget {
  final List<AiRuleModel> rules;
  final bool isLoading;
  final bool autoApprove;
  final Function(String) onApprove;
  final Function(String) onReject;
  final Function(String) onToggle;

  const _RulesSection({
    required this.rules,
    required this.isLoading,
    required this.autoApprove,
    required this.onApprove,
    required this.onReject,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rules.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: Text('No AI rules found.', style: TextStyle(color: Colors.black45, fontSize: 16))),
      );
    }

    return Column(
      children: rules
          .map((rule) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RuleCard(
                  rule: rule,
                  onApprove: () => onApprove(rule.id),
                  onReject: () => onReject(rule.id),
                  onToggle: () => onToggle(rule.id),
                ),
              ))
          .toList(),
    );
  }
}
