import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/nk_colors.dart';
import '../../../core/theme/nk_text_styles.dart';

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
          _SidebarLogo(),
          const Divider(color: Color(0xFFF2F4F7)),
          Expanded(
            child: ListView(
              children: [
                const _NavSection('DASHBOARD'),
                _NavItem(
                  LucideIcons.activity,
                  'Statistics',
                  route: '/dashboard',
                  isActive: currentRoute == '/dashboard',
                ),
                _NavItem(
                  LucideIcons.cpu,
                  'AI Generated Rules',
                  route: '/ai-rules',
                  isActive: currentRoute == '/ai-rules',
                ),
                _NavItem(
                  LucideIcons.list,
                  'Rules Management',
                  route: '/rules-management',
                  isActive: currentRoute == '/rules-management',
                ),
                const _NavSection('STATIC RULES'),
                _NavItem(
                  LucideIcons.monitor,
                  'Interfaces',
                  route: '/interfaces',
                  isActive: currentRoute == '/interfaces',
                ),
                _NavItem(
                  LucideIcons.table,
                  'Tables',
                  route: '/tables',
                  isActive: currentRoute == '/tables',
                ),
                _NavItem(
                  LucideIcons.database,
                  'Chains',
                  route: '/chains',
                  isActive: currentRoute == '/chains',
                ),
                _NavItem(
                  LucideIcons.layers,
                  'Rules',
                  route: '/rules',
                  isActive: currentRoute == '/rules',
                ),
                _NavItem(
                  LucideIcons.workflow,
                  'NAT',
                  route: '/nat',
                  isActive: currentRoute == '/nat',
                ),
                const _NavSection('ADMINISTRATION'),
                _NavItem(
                  LucideIcons.users,
                  'User Management',
                  route: '/users',
                  isActive: currentRoute == '/users',
                ),
                _NavItem(
                  LucideIcons.file,
                  'Reports',
                  route: '/reports',
                  isActive: currentRoute == '/reports',
                ),
              ],
            ),
          ),
          const _UserFooter(),
        ],
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(LucideIcons.shieldCheck, color: NKColors.blue, size: 30),
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

class _NavSection extends StatelessWidget {
  final String title;
  const _NavSection(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title, style: NKTextStyles.sidebarSection),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  const _NavItem(this.icon, this.label,
      {required this.route, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isActive ? NKColors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        color: isActive ? NKColors.blue.withOpacity(0.1) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(icon,
            size: 18,
            color:
                isActive ? const Color(0xFFDBDFE6) : const Color(0xFFB7A7A7)),
        title: Text(label,
            style: NKTextStyles.sidebarLabel.copyWith(
              color: isActive ? const Color(0xFFF7F5F5) : null,
            )),
        dense: true,
        onTap: () {
          if (!isActive) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  const _UserFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.logout, size: 16, color: Color(0xFFCAD0D9)),
                  SizedBox(width: 10),
                  Text('Log Out',
                      style: TextStyle(
                          color: Color(0xFFCBD1D9),
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(color: Color(0xFF4F5B6B), height: 1),
          ),
          Row(
            children: const [
              CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFFF2F5F8),
                child: Text('RA',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Root Admin',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text('Super Admin',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB1B9C4))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
