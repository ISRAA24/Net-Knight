import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/nk_colors.dart';
import '../dashboard/widgets/sidebar.dart';
import 'models/rule_model.dart';
import 'services/rule_management_service.dart';
import 'widgets/rule_table.dart';
import 'widgets/search_bar.dart';

class RuleManagementScreen extends StatefulWidget {
  const RuleManagementScreen({super.key});

  @override
  State<RuleManagementScreen> createState() => _RuleManagementScreenState();
}

class _RuleManagementScreenState extends State<RuleManagementScreen> {
  final _searchController = TextEditingController();
  final _service = RuleManagementService();

  String _searchQuery = '';
  List<RuleModel> _staticRules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAllRules();
      if (mounted) {
        setState(() {
          _staticRules = data['staticRules'];
          _isLoading = false;
        });
      }
    } on DioException catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<RuleModel> get _filtered {
    if (_searchQuery.isEmpty) return _staticRules;
    final q = _searchQuery.toLowerCase();
    return _staticRules
        .where((r) =>
            r.sourceIp.toLowerCase().contains(q) ||
            r.destIp.toLowerCase().contains(q) ||
            r.action.toLowerCase().contains(q) ||
            r.protocol.toLowerCase().contains(q))
        .toList();
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
                const _TopBar(title: 'Rule Management'),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: NKColors.blue),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RuleSearchBar(
                                controller: _searchController,
                                onChanged: (q) =>
                                    setState(() => _searchQuery = q),
                                totalRules: _staticRules.length,
                              ),
                              const SizedBox(height: 20),
                              RuleTable(
                                rules: _filtered,
                                // ← Future مباشرة للـ table يتعامل معاه
                                onToggle: (id) => _service.toggleRule(id),
                                onDelete: (id) async {
                                  await _service.deleteRule(id);
                                  _loadRules();
                                },
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

// ─── Top Bar ──────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

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
                  color: NKColors.onSurface,
                ),
              ),
              const Icon(LucideIcons.bell,
                  size: 22, color: NKColors.onSurface),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black12, height: 1),
        ],
      ),
    );
  }
}