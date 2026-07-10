import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:net_knight/core/network/base_services.dart';

import 'models/ai_rule_model_analyst.dart';
import 'services/ai_rules_service_analyst.dart';
import 'widgets/rule_card_analyst.dart';
import 'widgets/sidebar_analyst.dart';
import 'widgets/stats_row_analyst.dart';

class AiGeneratedRulesScreenAnalyst extends StatefulWidget {
  const AiGeneratedRulesScreenAnalyst({super.key});

  @override
  State<AiGeneratedRulesScreenAnalyst> createState() =>
      _AiGeneratedRulesScreenAnalystState();
}

class _AiGeneratedRulesScreenAnalystState
    extends State<AiGeneratedRulesScreenAnalyst> {
  final _service = AiRulesServiceAnalyst();

  List<AiRuleModelAnalyst> _rules = [];
  bool _isLoading = true;
  String? _error;

  String _username = 'User';
  String _role = '';
  String _initials = 'U';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadRules();
  }

  Future<void> _loadUserInfo() async {
    final username = await TokenStorage.getUsername();
    final role = await TokenStorage.getRole();
    if (mounted) {
      setState(() {
        _username = username;
        _role = role;
        _initials = _computeInitials(username);
      });
    }
  }

  String _computeInitials(String name) {
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return 'U';
  }

  Future<void> _loadRules() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rules = await _service.getRules();
      if (mounted) setState(() => _rules = rules);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load rules');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = AiRulesStatsAnalyst.fromRules(_rules);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          SidebarAnalyst(
            activeRoute: '/ai-rules',
            username: _username,
            role: _role,
            initials: _initials,
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                const _TopBarAnalyst(title: 'AI Generated Rules'),
                Expanded(child: _buildBody(stats)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AiRulesStatsAnalyst stats) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadRules, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRules,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats cards
            StatsRowAnalyst(stats: stats),
            const SizedBox(height: 20),

            // Section header
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
              'Rules awaiting approval: ${stats.pending}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Color.fromARGB(168, 0, 0, 0),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Rules list — read only للـ analyst
            if (_rules.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    'No AI rules found.',
                    style: TextStyle(color: Colors.black45, fontSize: 16),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rules.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, i) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 750),
                    child: RuleCardAnalyst(rule: _rules[i]),
                  ),
                ),
              ),
          ],
        ),
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