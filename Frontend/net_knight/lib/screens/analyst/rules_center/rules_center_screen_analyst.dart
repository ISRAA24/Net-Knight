import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ai_generated_rules/widgets/sidebar_analyst.dart';
import 'models/rules_center_model_analyst.dart';
import 'services/rules_center_service_analyst.dart';
import 'widgets/firewall_table_analyst.dart';
import 'widgets/nat_table_analyst.dart';
import 'widgets/view_selector_analyst.dart';

class RulesCenterScreenAnalyst extends StatefulWidget {
  const RulesCenterScreenAnalyst({super.key});

  @override
  State<RulesCenterScreenAnalyst> createState() =>
      _RulesCenterScreenAnalystState();
}

class _RulesCenterScreenAnalystState extends State<RulesCenterScreenAnalyst> {
  final _service = RulesCenterServiceAnalyst();

  RulesCenterDataAnalyst? _data;
  bool _isLoading = true;
  String? _error;

  RuleViewAnalyst _activeView = RuleViewAnalyst.firewall;
  final _searchController = TextEditingController();
  final _natSearchController = TextEditingController();
  String _searchQuery = '';
  String _natSearchQuery = '';

  String _username = '';
  String _role = '';
  String _initials = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _natSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _username = 'Analyst';
      _role = 'Analyst';
      _initials = 'AN';
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getFirewallRules(),
        _service.getNatRules(),
      ]);
      if (mounted) {
        setState(
          () => _data = RulesCenterDataAnalyst(
            firewallRules: results[0] as List<FirewallRuleModelAnalyst>,
            natRules: results[1] as List<NatRuleModelAnalyst>,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load rules');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Search filters ───────────────────────────────────────
  List<FirewallRuleModelAnalyst> get _filteredFirewall {
    final rules = _data?.firewallRules ?? [];
    if (_searchQuery.isEmpty) return rules;
    final q = _searchQuery.toLowerCase();
    return rules
        .where(
          (r) =>
              r.sourceIp.toLowerCase().contains(q) ||
              r.destination.toLowerCase().contains(q) ||
              r.action.toLowerCase().contains(q) ||
              r.protocol.toLowerCase().contains(q) ||
              r.origin.toLowerCase().contains(q),
        )
        .toList();
  }

  List<NatRuleModelAnalyst> get _filteredNat {
    final rules = _data?.natRules ?? [];
    if (_natSearchQuery.isEmpty) return rules;
    final q = _natSearchQuery.toLowerCase();
    return rules
        .where(
          (r) =>
              r.sourceIp.toLowerCase().contains(q) ||
              r.destIp.toLowerCase().contains(q) ||
              r.interfaceName.toLowerCase().contains(q) ||
              r.natType.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isFirewall = _activeView == RuleViewAnalyst.firewall;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          SidebarAnalyst(
            activeRoute: '/rules-center',
            username: _username,
            role: _role,
            initials: _initials,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TopBarAnalyst(title: 'Rules Center'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? _ErrorView(message: _error!, onRetry: _loadData)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // View selector
                              ViewSelectorAnalyst(
                                active: _activeView,
                                onChanged: (v) =>
                                    setState(() => _activeView = v),
                              ),
                              const SizedBox(height: 16),

                              // Search bar + count badge
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: TextField(
                                        controller: isFirewall
                                            ? _searchController
                                            : _natSearchController,
                                        onChanged: (v) => setState(() {
                                          if (isFirewall) {
                                            _searchQuery = v;
                                          } else {
                                            _natSearchQuery = v;
                                          }
                                        }),
                                        style: const TextStyle(fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: isFirewall
                                              ? 'Search rules by name, IP, or action...'
                                              : 'Search by IP, protocol, action...',
                                          hintStyle: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                          prefixIcon: const Icon(
                                            LucideIcons.search,
                                            size: 15,
                                            color: Colors.black54,
                                          ),
                                          contentPadding: EdgeInsets.zero,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.black,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.black,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF3B82F6),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2965C5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.filter_alt,
                                          size: 15,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isFirewall
                                              ? '${_data?.firewallRules.length ?? 0} Rules'
                                              : '${_data?.natRules.length ?? 0} NAT Rules',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Table
                              if (isFirewall)
                                Expanded(
                                  child: FirewallTableAnalyst(
                                    rows: _filteredFirewall,
                                  ),
                                )
                              else
                                SingleChildScrollView(
                                  child: NatTableAnalyst(rows: _filteredNat),
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

// ─── Top Bar ──────────────────────────────────────────────────
class _TopBarAnalyst extends StatelessWidget {
  final String title;
  const _TopBarAnalyst({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.rajdhani(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1D242B),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.bell, size: 22),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black12, height: 1),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
