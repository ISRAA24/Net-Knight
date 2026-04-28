import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/nk_colors.dart';
import '../dashboard/widgets/sidebar.dart';
import 'models/rule_model.dart';
import 'services/rules_service.dart';
import 'widgets/rule_form.dart';
import 'widgets/command_preview.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  final _ipSourceController = TextEditingController();
  final _ipDestController = TextEditingController();
  final _portDestController = TextEditingController();
  final _service = RulesService();

  List<String> _tables = [];
  List<String> _chains = [];
  String _selectedTableName = '';
  String _selectedChainName = '';
  String? _selectedInterface;
  String? _selectedProtocol;
  String? _selectedAction;
  bool _isSuccess = false;
  bool _isLoading = false;

  String _previewCommand = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadTables();
    _ipSourceController.addListener(_onChanged);
    _ipDestController.addListener(_onChanged);
    _portDestController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ipSourceController.dispose();
    _ipDestController.dispose();
    _portDestController.dispose();
    super.dispose();
  }

  // ─── Load Tables ──────────────────────────────────
  Future<void> _loadTables() async {
    try {
      final tables = await _service.getTables();
      if (mounted) {
        setState(() {
          _tables = tables;
          _selectedTableName = tables.isNotEmpty ? tables.first : '';
        });
        if (tables.isNotEmpty) _loadChains(tables.first);
      }
    } catch (_) {
      if (mounted) setState(() => _tables = []);
    }
  }

  // ─── Load Chains حسب الـ table ────────────────────
  Future<void> _loadChains(String tableName) async {
    setState(() => _chains = []);
    try {
      final chains = await _service.getChains(tableName);
      if (mounted) {
        setState(() {
          _chains = chains;
          _selectedChainName = chains.isNotEmpty ? chains.first : '';
        });
        _updatePreview();
      }
    } catch (_) {
      if (mounted) setState(() => _chains = []);
    }
  }

  // ─── Preview (debounced) ──────────────────────────
  void _updatePreview() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final rule = RuleModel(
          tableName: _selectedTableName,
          chainName: _selectedChainName,
          ipSource: _ipSourceController.text.trim(),
          ipDestination: _ipDestController.text.trim(),
          portDestination: _portDestController.text.trim(),
          interface: _selectedInterface ?? '',
          protocol: _selectedProtocol ?? '',
          action: _selectedAction ?? '',
        );
        final command = await _service.previewRule(rule);
        if (mounted) setState(() => _previewCommand = command);
      } catch (_) {}
    });
  }

  // ─── On Any Field Changed ─────────────────────────
  void _onChanged() {
    if (_isSuccess) setState(() => _isSuccess = false);
    _updatePreview();
  }

  // ─── Add Rule ─────────────────────────────────────
  Future<void> _addRule() async {
    if (_selectedTableName.isEmpty ||
        _selectedChainName.isEmpty ||
        _selectedAction == null) {
      _showError('Please fill in all required fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rule = RuleModel(
        tableName: _selectedTableName,
        chainName: _selectedChainName,
        ipSource: _ipSourceController.text.trim(),
        ipDestination: _ipDestController.text.trim(),
        portDestination: _portDestController.text.trim(),
        interface: _selectedInterface ?? '',
        protocol: _selectedProtocol ?? '',
        action: _selectedAction ?? '',
      );
      await _service.addRule(rule);
      if (mounted) setState(() => _isSuccess = true);
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 409
          ? 'Rule already exists'
          : 'Connection error. Please try again.';
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      backgroundColor: NKColors.bg,
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: 'Rules'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                    child: Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        // ─── Form ──────────────────────
                        SingleChildScrollView(
                          child: RuleForm(
                            tables: _tables,
                            chains: _chains,
                            selectedTableName: _selectedTableName,
                            selectedChainName: _selectedChainName,
                            ipSourceController: _ipSourceController,
                            ipDestController: _ipDestController,
                            portDestController: _portDestController,
                            selectedInterface: _selectedInterface,
                            selectedProtocol: _selectedProtocol,
                            selectedAction: _selectedAction,
                            onTableChanged: (val) {
                              setState(() => _selectedTableName = val);
                              _loadChains(val);
                              _onChanged();
                            },
                            onChainChanged: (val) => setState(() {
                              _selectedChainName = val;
                              _onChanged();
                            }),
                            onInterfaceChanged: (val) => setState(() {
                              _selectedInterface = val;
                              _onChanged();
                            }),
                            onProtocolChanged: (val) => setState(() {
                              _selectedProtocol = val;
                              _onChanged();
                            }),
                            onActionChanged: (val) => setState(() {
                              _selectedAction = val;
                              _onChanged();
                            }),
                            onChanged: _onChanged,
                          ),
                        ),

                        // ─── Command Preview ───────────
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 80,
                          child: CommandPreview(
                            command: _previewCommand,
                            isSuccess: _isSuccess,
                          ),
                        ),

                        // ─── FAB ───────────────────────
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: _AddButton(
                            isLoading: _isLoading,
                            onTap: _addRule,
                          ),
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
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
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
              const Icon(LucideIcons.bell, size: 22, color: Color(0xFF1D242B)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black12, height: 1),
        ],
      ),
    );
  }
}

// ─── Add Button ───────────────────────────────────────────

class _AddButton extends StatelessWidget {
  const _AddButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
