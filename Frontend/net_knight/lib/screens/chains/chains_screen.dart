import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/nk_colors.dart';
import '../dashboard/widgets/sidebar.dart';
import 'models/chain_model.dart';
import 'services/chains_service.dart';
import 'widgets/chain_form.dart';
import 'widgets/command_preview.dart';

class ChainsScreen extends StatefulWidget {
  const ChainsScreen({super.key});

  @override
  State<ChainsScreen> createState() => _ChainsScreenState();
}

class _ChainsScreenState extends State<ChainsScreen> {
  final _chainNameController = TextEditingController();
  final _priorityController = TextEditingController(text: '0');
  final _service = ChainsService();

  List<String> _tables = [];
  String _selectedTableName = '';
  String _selectedHook = 'prerouting';
  String _selectedPolicy = 'accept';
  String _selectedType = 'route';
  int _priorityValue = 0;
  bool _isSuccess = false;
  bool _isLoading = false;

  String _previewCommand = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadTables();
    _chainNameController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _chainNameController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  // ─── Load Tables ──────────────────────────────────────
  Future<void> _loadTables() async {
    try {
      final tables = await _service.getTables();
      if (mounted) {
        setState(() {
          _tables = tables;
          _selectedTableName = tables.isNotEmpty ? tables.first : '';
        });
        _updatePreview();
      }
    } catch (e) {
      print('Error loading tables: $e');
      if (mounted) setState(() => _tables = []);
    }
  }

  // ─── Reset Fields ─────────────────────────────────────
  void _resetFields() {
    _chainNameController.clear();
    _priorityController.text = '0';
    setState(() {
      _selectedTableName = _tables.isNotEmpty ? _tables.first : '';
      _selectedHook = 'prerouting';
      _selectedPolicy = 'accept';
      _selectedType = 'route';
      _priorityValue = 0;
      _previewCommand = '';
    });
  }

  // ─── Preview (debounced) ──────────────────────────────
  void _updatePreview() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      // ← لو table أو chain name فاضيين متبعتش request
      if (_selectedTableName.isEmpty ||
          _chainNameController.text.trim().isEmpty) {
        if (mounted) setState(() => _previewCommand = '');
        return;
      }
      try {
        final chain = ChainModel(
          tableName: _selectedTableName,
          chainName: _chainNameController.text.trim(),
          hook: _selectedHook,
          policy: _selectedPolicy,
          type: _selectedType,
          priority: _priorityValue,
        );
        final command = await _service.previewChain(chain);
        if (mounted) setState(() => _previewCommand = command);
      } catch (e) {
        print('Error previewing chain: $e');
      }
    });
  }

  // ─── On Any Field Changed ─────────────────────────────
  void _onChanged() {
    if (_isSuccess) setState(() => _isSuccess = false);
    _updatePreview();
  }

  // ─── Add Chain ────────────────────────────────────────
  Future<void> _addChain() async {
    final chainName = _chainNameController.text.trim();

    if (_selectedTableName.isEmpty || chainName.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final chain = ChainModel(
        tableName: _selectedTableName,
        chainName: chainName,
        hook: _selectedHook,
        policy: _selectedPolicy,
        type: _selectedType,
        priority: _priorityValue,
      );
      await _service.addChain(chain);
      if (mounted) {
        setState(() => _isSuccess = true);
        // ← بعد ثانيتين يظهر الـ success ثم يعمل reset
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _isSuccess = false);
          _resetFields();
        }
      }
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 409
          ? 'Chain already exists'
          : 'Connection error. Please try again.';
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Color(0xffef4444)),
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
                _TopBar(title: 'Chains'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                    child: Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        // ─── Form ──────────────────────
                        SingleChildScrollView(
                          child: ChainForm(
                            tables: _tables,
                            selectedTableName: _selectedTableName,
                            chainNameController: _chainNameController,
                            priorityController: _priorityController,
                            selectedHook: _selectedHook,
                            selectedPolicy: _selectedPolicy,
                            selectedType: _selectedType,
                            priorityValue: _priorityValue,
                            onTableChanged: (val) => setState(() {
                              _selectedTableName = val;
                              _onChanged();
                            }),
                            onHookChanged: (val) => setState(() {
                              _selectedHook = val;
                              _onChanged();
                            }),
                            onPolicyChanged: (val) => setState(() {
                              _selectedPolicy = val;
                              _onChanged();
                            }),
                            onTypeChanged: (val) => setState(() {
                              _selectedType = val;
                              _onChanged();
                            }),
                            onPriorityUp: () => setState(() {
                              _priorityValue++;
                              _priorityController.text =
                                  _priorityValue.toString();
                              _onChanged();
                            }),
                            onPriorityDown: () => setState(() {
                              if (_priorityValue > 0) _priorityValue--;
                              _priorityController.text =
                                  _priorityValue.toString();
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
                            onTap: _addChain,
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
          const Divider(color: Color(0xff1d242b), height: 1),
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
              color: const Color(0xff0077c0).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                    color: Color(0xfffafafa), strokeWidth: 2),
              )
            : const Icon(Icons.add, color: Color(0xfffafafa), size: 28),
      ),
    );
  }
}
