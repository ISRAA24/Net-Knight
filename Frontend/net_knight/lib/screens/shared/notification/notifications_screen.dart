import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:net_knight/main.dart';
import 'package:net_knight/core/network/base_services.dart';
import 'package:net_knight/screens/admin/dashboard/widgets/sidebar.dart';
import 'package:net_knight/screens/analyst/ai_generated_rules/widgets/sidebar_analyst.dart';
import 'package:provider/provider.dart';

import 'models/notification_model.dart';
import 'services/notification_service.dart';
import 'widgets/notification_card.dart';

class NotificationsScreenAdmin extends StatefulWidget {
  const NotificationsScreenAdmin({super.key});

  @override
  State<NotificationsScreenAdmin> createState() =>
      _NotificationsScreenAdminState();
}

class _NotificationsScreenAdminState extends State<NotificationsScreenAdmin> {
  final _service = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  String _username = 'User';
  String _role = '';
  String _initials = 'U';
  bool get _isAnalyst => _role.toLowerCase() == 'analyst';

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadNotifications();
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

  void _syncProvider() {
    if (!mounted) return;
    context.read<NotificationProvider>().updateUnreadCount(_unreadCount);
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      _notifications = await _service.getNotifications();
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _syncProvider();
    }
  }

  Future<void> _markAsRead(String id) async {
    final success = await _service.markAsRead(id);
    if (success) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
      _syncProvider();
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await _service.markAllAsRead();
    if (success) {
      setState(() {
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
      });
      _syncProvider();
    }
  }

  Future<void> _deleteNotification(String id) async {
    final success = await _service.deleteNotification(id);
    if (success) {
      setState(() {
        _notifications.removeWhere((n) => n.id == id);
      });
      _syncProvider();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: Row(
        children: [
          _isAnalyst
              ? SidebarAnalyst(
                  activeRoute: '/notifications',
                  username: _username,
                  role: _role,
                  initials: _initials,
                )
              : const Sidebar(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  unreadCount: _unreadCount,
                  onMarkAllRead: _markAllAsRead,
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            const _SectionLabel('TODAY'),
                            ..._notifications.map(
                              (n) => NotificationCard(
                                notification: n,
                                onMarkRead: () => _markAsRead(n.id),
                                onDelete: () => _deleteNotification(n.id),
                              ),
                            ),
                            if (_notifications.isEmpty)
                              const Center(
                                child: Text(
                                  'No notifications',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                          ],
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

class _Header extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onMarkAllRead;

  const _Header({required this.unreadCount, required this.onMarkAllRead});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$unreadCount new',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const Spacer(),
          if (unreadCount > 0)
            TextButton(
              onPressed: onMarkAllRead,
              child: const Text(
                'Mark all as read',
                style: TextStyle(color: Colors.blue, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
