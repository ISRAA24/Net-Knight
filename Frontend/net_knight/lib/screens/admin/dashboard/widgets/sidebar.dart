import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:net_knight/core/network/base_services.dart';
import 'package:net_knight/core/theme/nk_colors.dart';
import 'package:net_knight/core/theme/nk_text_styles.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/dashboard';

    return Container(
      width: 220,
      color: NKColors.sidebar,
      child: Column(
        children: [
          const _SidebarLogo(),
          const Divider(color: Color(0xFFF2F4F7)),
          Expanded(
            child: ListView(
              children: [
                const _NavSection('DASHBOARD'),
                _NavItem(LucideIcons.activity, 'Statistics',
                    route: '/dashboard',
                    isActive: currentRoute == '/dashboard'),
                _NavItem(LucideIcons.cpu, 'AI Generated Rules',
                    route: '/ai-rules-admin', isActive: currentRoute == '/ai-rules-admin'),
                _NavItem(LucideIcons.list, 'Rules Management',
                    route: '/rules-management',
                    isActive: currentRoute == '/rules-management'),
                const _NavSection('STATIC RULES'),
                _NavItem(LucideIcons.monitor, 'Interfaces',
                    route: '/interfaces',
                    isActive: currentRoute == '/interfaces'),
                _NavItem(LucideIcons.table, 'Tables',
                    route: '/tables', isActive: currentRoute == '/tables'),
                _NavItem(LucideIcons.database, 'Chains',
                    route: '/chains', isActive: currentRoute == '/chains'),
                _NavItem(LucideIcons.layers, 'Rules',
                    route: '/rules', isActive: currentRoute == '/rules'),
                _NavItem(LucideIcons.workflow, 'NAT',
                    route: '/nat', isActive: currentRoute == '/nat'),
                const _NavSection('ADMINISTRATION'),
                _NavItem(LucideIcons.users, 'User Management',
                    route: '/users', isActive: currentRoute == '/users'),
                _NavItem(LucideIcons.file, 'Reports',
                    route: '/reports-admin', isActive: currentRoute == '/reports-admin'),
              ],
            ),
          ),
          const _UserFooter(),
        ],
      ),
    );
  }
}

// ── Logo ────────────────────────────────────────────────────────────────────

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Image.asset('assets/images/logo.png', width: 30, height: 30),
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
    );
  }
}

// ── Section label ────────────────────────────────────────────────────────────

class _NavSection extends StatelessWidget {
  const _NavSection(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title, style: NKTextStyles.sidebarSection),
    );
  }
}

// ── Nav item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem(this.icon, this.label, {required this.route, this.isActive = false});

  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFFDBDFE6) : const Color(0xFFB7A7A7);

    return Material( 
      color: isActive ? NKColors.blue.withOpacity(0.1) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, size: 18, color: color),
        title: Text(
          label,
          style: NKTextStyles.sidebarLabel.copyWith(
            color: isActive ? const Color(0xFFF7F5F5) : null,
          ),
        ),
        dense: true,
        onTap: () {
          if (!isActive) Navigator.pushReplacementNamed(context, route);
        },
      ),
    );
  }
}

// ── User footer ───────────────────────────────────────────────────────────────

class _UserFooter extends StatefulWidget {
  const _UserFooter();

  @override
  State<_UserFooter> createState() => _UserFooterState();
}

class _UserFooterState extends State<_UserFooter> {
  String _username = 'User';
  String _role = '';
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final username = await TokenStorage.getUsername();
    final role = await TokenStorage.getRole();
    if (mounted)
      setState(() {
        _username = username;
        _role = role;
      });
  }

  String get _initials {
    if (_username.length >= 2) return _username.substring(0, 2).toUpperCase();
    if (_username.isNotEmpty) return _username[0].toUpperCase();
    return 'U';
  }

  // ⚠️ FIX: this previously only cleared the local token — it never
  // called POST /auth/logout, so the httpOnly cookie on the backend was
  // never cleared and the "System Logout" activity log entry was never
  // written. We now call the backend first (best-effort — logout should
  // still proceed locally even if the request fails, e.g. offline).
  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await BaseService.dio.post('/auth/logout');
    } catch (_) {
      // Ignore network errors here — we still want to clear the local
      // session and navigate to login even if the backend call failed.
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _isLoggingOut ? null : _logout,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 16, color: Color(0xFFCAD0D9)),
                  const SizedBox(width: 10),
                  Text(
                    _isLoggingOut ? 'Logging out...' : 'Log Out',
                    style: const TextStyle(
                        color: Color(0xFFCBD1D9),
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(color: Color(0xFF4F5B6B), height: 1),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFF2F5F8),
                child: Text(
                  _initials,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_username,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text(_role,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFB1B9C4))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}