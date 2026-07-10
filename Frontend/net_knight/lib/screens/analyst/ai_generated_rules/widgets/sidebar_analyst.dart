import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:net_knight/core/network/base_services.dart';
import 'package:net_knight/core/theme/nk_colors.dart';

class SidebarAnalyst extends StatelessWidget {
  const SidebarAnalyst({
    super.key,
    required this.activeRoute,
    required this.username,
    required this.role,
    required this.initials,
  });

  final String activeRoute;
  final String username;
  final String role;
  final String initials;

  static const _kSidebarColor = Color(0xDA000000);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: _kSidebarColor,
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldCheck,
                    color: NKColors.primary, size: 30),
                const SizedBox(width: 10),
                Text(
                  'NETKNIGHT',
                  style: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),

          Expanded(
            child: ListView(
              children: [
                _NavSectionAnalyst('DASHBOARD'),
                _NavItemAnalyst(
                  icon: LucideIcons.activity,
                  label: 'Statistics',
                  route: '/statistics',
                  activeRoute: activeRoute,
                ),
                _NavItemAnalyst(
                  icon: LucideIcons.cpu,
                  label: 'AI Generated Rules',
                  route: '/ai-rules',
                  activeRoute: activeRoute,
                ),
                _NavItemAnalyst(
                  icon: LucideIcons.list,
                  label: 'Rules Center',
                  route: '/rules-center',
                  activeRoute: activeRoute,
                ),
                _NavSectionAnalyst('ADMINISTRATION'),
                _NavItemAnalyst(
                  icon: LucideIcons.file,
                  label: 'Reports',
                  route: '/reports',
                  activeRoute: activeRoute,
                ),
              ],
            ),
          ),

          // Footer
          _SidebarFooterAnalyst(
            username: username,
            role: role,
            initials: initials,
          ),
        ],
      ),
    );
  }
}

// ─── Nav Section Label ────────────────────────────────────────
class _NavSectionAnalyst extends StatelessWidget {
  const _NavSectionAnalyst(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF8BA8A8),
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
      );
}

// ─── Nav Item ────────────────────────────────────────────────
class _NavItemAnalyst extends StatelessWidget {
  const _NavItemAnalyst({
    required this.icon,
    required this.label,
    required this.route,
    required this.activeRoute,
  });

  final IconData icon;
  final String label;
  final String route;
  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    final isActive = activeRoute == route;
    final color = isActive ? Colors.white : const Color(0xFFB7A7A7);

    return Material(  
      color: isActive ? NKColors.primary.withOpacity(0.1) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, size: 18, color: color),
        title: Text(
          label,
          style: GoogleFonts.rajdhani(fontSize: 13, color: color),
        ),
        dense: true,
        onTap: () => Navigator.pushReplacementNamed(context, route),
      ),
    );
  }
}

// ─── Sidebar Footer ──────────────────────────────────────────
class _SidebarFooterAnalyst extends StatefulWidget {
  const _SidebarFooterAnalyst({
    required this.username,
    required this.role,
    required this.initials,
  });

  final String username;
  final String role;
  final String initials;

  @override
  State<_SidebarFooterAnalyst> createState() => _SidebarFooterAnalystState();
}

class _SidebarFooterAnalystState extends State<_SidebarFooterAnalyst> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await BaseService.dio.post('/auth/logout');
    } catch (_) {
      // Best-effort: still log out locally even if the request fails.
    } finally {
      await TokenStorage.deleteToken();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logout
          InkWell(
            onTap: _isLoggingOut ? null : _logout,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 16, color: Color(0xFFCBD1D9)),
                  const SizedBox(width: 10),
                  Text(
                    _isLoggingOut ? 'Logging out...' : 'Log Out',
                    style: const TextStyle(
                      color: Color(0xFFCBD1D9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Color(0xFF4F5B6B), height: 8),
          const SizedBox(height: 4),

          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFF2F5F8),
                child: Text(
                  widget.initials,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.username,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.role,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFB1B9C4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}