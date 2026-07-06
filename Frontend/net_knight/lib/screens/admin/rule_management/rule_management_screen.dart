import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:net_knight/main.dart';
import 'package:net_knight/screens/admin/dashboard/widgets/sidebar.dart';
import 'package:provider/provider.dart';

import 'models/rule_management_model.dart';
import 'services/rule_management_service.dart';
import 'widgets/rule_table.dart';
import 'widgets/nat_table.dart';

class RuleManagementScreen extends StatefulWidget {
  const RuleManagementScreen({super.key});

  @override
  State<RuleManagementScreen> createState() => _RuleManagementScreenState();
}

class _RuleManagementScreenState extends State<RuleManagementScreen> {
  final _service = RuleService();
  RuleView _activeView = RuleView.firewall;

  List<RuleModel> _rules = [];
  List<NatRuleModel> _natRules = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final TextEditingController _natSearchController = TextEditingController();
  String _natSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _natSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _rules = await _service.getAllRules();
      _natRules = await _service.getNatRules();
    } catch (e) {
      print('Error loading rules: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<RuleModel> get _filteredRules {
    if (_searchQuery.isEmpty) return _rules;
    final q = _searchQuery.toLowerCase();
    return _rules
        .where(
          (r) =>
              r.sourceIp.toLowerCase().contains(q) ||
              r.ruleName.toLowerCase().contains(q) ||
              r.action.toLowerCase().contains(q) ||
              r.origin.toLowerCase().contains(q),
        )
        .toList();
  }

  List<NatRuleModel> get _natFilteredRules {
    if (_natSearchQuery.isEmpty) return _natRules;
    final q = _natSearchQuery.toLowerCase();
    return _natRules
        .where(
          (r) =>
              r.sourceIp.toLowerCase().contains(q) ||
              r.destIp.toLowerCase().contains(q) ||
              r.natType.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _toggleRule(String id, bool enabled , bool isAi ) async {
    final success = await _service.toggleRule(id, isAi: isAi);
    if (success) {
      _loadData();
    } else if (mounted) {
      _showError('Failed to update rule');
    }
  }

  Future<void> _deleteRule(String id , bool isAi ) async {
    final success = await _service.deleteRule(id, isAi: isAi);
    if (success) {
      _loadData();
    } else if (mounted) {
      _showError('Failed to delete rule');
    }
  }

  Future<void> _toggleNatRule(String id, bool enabled) async {
    final success = await _service.toggleNatRule(id);
    if (success) {
      _loadData();
    } else if (mounted) {
      _showError('Failed to update NAT rule');
    }
  }

  Future<void> _deleteNatRule(String id) async {
    final success = await _service.deleteNatRule(id);
    if (success) {
      _loadData();
    } else if (mounted) {
      _showError('Failed to delete NAT rule');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
                const _TopBar(title: 'Rules Center'),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      // ⚠️ FIX: the table now lives inside a scroll view and
                      // sizes itself to its own content (grows/shrinks with
                      // the number of rows) instead of being force-fit into a
                      // fixed Expanded area that used to clip/overflow.
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ViewSelector(
                                active: _activeView,
                                onChanged: (v) => setState(() => _activeView = v),
                              ),
                              const SizedBox(height: 16),
                              _buildSearchBar(),
                              const SizedBox(height: 20),
                              _activeView == RuleView.firewall
                                  ? RuleTable(
                                      rules: _filteredRules,
                                      onToggle: _toggleRule,
                                      onDelete: _deleteRule,
                                    )
                                  : NatTable(
                                      natRules: _natFilteredRules,
                                      onToggle: _toggleNatRule,
                                      onDelete: _deleteNatRule,
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

  Widget _buildSearchBar() {
    final isFirewall = _activeView == RuleView.firewall;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: isFirewall ? _searchController : _natSearchController,
              onChanged: (v) => setState(() {
                if (isFirewall) {
                  _searchQuery = v;
                } else {
                  _natSearchQuery = v;
                }
              }),
              decoration: InputDecoration(
                hintText: isFirewall
                    ? 'Search rules...'
                    : 'Search NAT rules...',
                prefixIcon: const Icon(LucideIcons.search, size: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// View Selector
class _ViewSelector extends StatelessWidget {
  final RuleView active;
  final ValueChanged<RuleView> onChanged;

  const _ViewSelector({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RadioOption(
          label: 'Firewall Rules',
          selected: active == RuleView.firewall,
          onTap: () => onChanged(RuleView.firewall),
        ),
        const SizedBox(width: 28),
        _RadioOption(
          label: 'NAT Rules',
          selected: active == RuleView.nat,
          onTap: () => onChanged(RuleView.nat),
        ),
      ],
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.blue : Colors.black45,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Center(
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: Colors.blue,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.black : Colors.black54,
              ),
            ),
          ],
        ),
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
