import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/nk_colors.dart';
import '../dashboard/widgets/sidebar.dart';
import 'models/user_model.dart';
import 'services/user_management_service.dart';
import 'widgets/user_card.dart';
import 'widgets/user_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _service = UserManagementService();
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // ─── Load ─────────────────────────────────
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _service.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } on DioException catch (_) {
      if (mounted) setState(() => _isLoading = false);
      _showError('Failed to load users');
    }
  }

  // ─── Add ──────────────────────────────────
  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (_) => UserDialog(
        onSave: (name, email, password, role) async {
          await _service.addUser(
            name: name,
            email: email,
            password: password,
            role: role,
          );
          await _loadUsers();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  // ─── Edit ─────────────────────────────────
  void _openEditDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (_) => UserDialog(
        isEditing: true,
        initialName: user.name,
        initialEmail: user.email,
        initialRole: user.role,
        onSave: (name, email, password, role) async {
          await _service.editUser(
            user.id,
            user.copyWith(name: name, email: email, role: role),
          );
          await _loadUsers();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  // ─── Delete ───────────────────────────────
  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "${user.name}"?'),
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
        await _service.deleteUser(user.id);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on DioException catch (_) {
        _showError('Failed to delete user');
      }
    }
  }

  bool _isActionAllowed(UserModel user) =>
      user.role != 'super_admin' && user.role != 'Super Admin';

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Color(0xffEF4444)),
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
                _TopBar(title: 'User Management'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF0077C0)),
                          )
                        : Stack(
                            children: [
                              _users.isEmpty
                                  ? const Center(
                                      child: Text('No users found'),
                                    )
                                  : ListView.builder(
                                      itemCount: _users.length,
                                      itemBuilder: (_, i) => UserCard(
                                        user: _users[i],
                                        onEdit: _isActionAllowed(_users[i])
                                            ? () => _openEditDialog(_users[i])
                                            : null,
                                        onDelete: _isActionAllowed(_users[i])
                                            ? () => _deleteUser(_users[i])
                                            : null,
                                      ),
                                    ),
                              Positioned(
                                bottom: 20,
                                right: 20,
                                child: FloatingActionButton(
                                  onPressed: _openAddDialog,
                                  backgroundColor: const Color(0xFF3B82F6),
                                  child: const Icon(Icons.add,
                                      color: Colors.white, size: 30),
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
