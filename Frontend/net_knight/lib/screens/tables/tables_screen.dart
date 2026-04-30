import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/theme/nk_colors.dart';
import '../dashboard/widgets/sidebar.dart';
import 'models/table_model.dart';
import 'services/tables_service.dart';
import 'widgets/table_form.dart';
import 'widgets/command_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  final _nameController = TextEditingController();
  final _service = TablesService();

  String _selectedFamily = 'ip';
  bool _isSuccess = false;
  bool _isLoading = false;

  String _previewCommand = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  // ─── Reset Fields ─────────────────────────────────────
  void _resetFields() {
    _nameController.clear();
    setState(() {
      _selectedFamily = 'ip';
      _previewCommand = '';
    });
  }

  // ─── Preview (debounced) ──────────────────────────────
  void _updatePreview() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      // ← لو name فاضي متبعتش request
      if (_nameController.text.trim().isEmpty) {
        if (mounted) setState(() => _previewCommand = '');
        return;
      }
      try {
        final table = TableModel(
          name: _nameController.text.trim(),
          family: _selectedFamily,
        );
        final command = await _service.previewTable(table);
        if (mounted) setState(() => _previewCommand = command);
      } catch (e) {
        print('Error previewing table: $e');
      }
    });
  }

  // ─── On Any Field Changed ─────────────────────────────
  void _onChanged() {
    if (_isSuccess) setState(() => _isSuccess = false);
    _updatePreview();
  }

  // ─── Add Table ────────────────────────────────────────
  Future<void> _addTable() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter a table name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final table = TableModel(name: name, family: _selectedFamily);
      await _service.addTable(table);
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
          ? 'Table already exists'
          : 'Connection error. Please try again.';
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message), backgroundColor: const Color(0xffef4444)),
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
                _TopBar(title: 'Tables'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Stack(
                      children: [
                        // ─── Form ──────────────────────
                        TableForm(
                          nameController: _nameController,
                          selectedFamily: _selectedFamily,
                          onFamilyChanged: (val) => setState(() {
                            _selectedFamily = val;
                            _onChanged();
                          }),
                          onNameChanged: (_) => _onChanged(),
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
                            onTap: _addTable,
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
          color: NKColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: NKColors.primary.withOpacity(0.4),
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
