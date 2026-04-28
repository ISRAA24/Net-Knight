import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/nk_colors.dart';
import '../dashboard/widgets/sidebar.dart';
import 'models/interface_model.dart';
import 'services/interfaces_service.dart';
import 'widgets/interfaces_table.dart';
import 'widgets/edit_interface_dialog.dart';
import 'widgets/search_bar.dart';

class InterfacesScreen extends StatefulWidget {
  const InterfacesScreen({super.key});

  @override
  State<InterfacesScreen> createState() => _InterfacesScreenState();
}

class _InterfacesScreenState extends State<InterfacesScreen> {
  final _service = InterfacesService();

  List<InterfaceModel> _all = [];
  List<InterfaceModel> _filtered = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInterfaces();
  }

  // ─── Load ─────────────────────────────────────────
  Future<void> _loadInterfaces() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getInterfaces();
      if (mounted) {
        setState(() {
          _all = data;
          _applySearch(_searchQuery);
          _isLoading = false;
        });
      }
    } on DioException catch (_) {
      if (mounted) setState(() => _isLoading = false);
      _showError('Failed to load interfaces');
    }
  }

  // ─── Search ───────────────────────────────────────
  void _applySearch(String query) {
    _searchQuery = query;
    final q = query.toLowerCase();
    _filtered = q.isEmpty
        ? List.of(_all)
        : _all
            .where((i) =>
                i.logicalName.toLowerCase().contains(q) ||
                i.realName.toLowerCase().contains(q) ||
                i.ip.toLowerCase().contains(q) ||
                i.status.toLowerCase().contains(q))
            .toList();
  }

  // ─── Edit ─────────────────────────────────────────
  void _showEditDialog(InterfaceModel item) {
    showDialog(
      context: context,
      builder: (_) => EditInterfaceDialog(
        item: item,
        onSave: (updated) => _editInterface(item, updated),
      ),
    );
  }

  Future<void> _editInterface(
      InterfaceModel old, InterfaceModel updated) async {
    try {
      await _service.editInterface(old.realName, updated);
      await _loadInterfaces();
    } on DioException catch (_) {
      _showError('Failed to update interface');
    }
  }

  // ─── Delete ───────────────────────────────────────
  Future<void> _deleteInterface(InterfaceModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Interface'),
        content: Text('Are you sure you want to delete "${item.logicalName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteInterface(item.realName);
        await _loadInterfaces();
      } on DioException catch (_) {
        _showError('Failed to delete interface');
      }
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(title: 'Interfaces'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Search ────────────────────
                        InterfaceSearchBar(
                          onChanged: (q) => setState(() => _applySearch(q)),
                        ),
                        const SizedBox(height: 20),

                        // ─── Table ─────────────────────
                        _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF0077C0)),
                              )
                            : InterfacesTable(
                                interfaces: _filtered,
                                onEdit: _showEditDialog,
                                onDelete: _deleteInterface,
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
              Text(title,
                  style: GoogleFonts.rajdhani(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1D242B),
                  )),
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
