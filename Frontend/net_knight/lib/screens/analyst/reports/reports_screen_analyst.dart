import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:net_knight/core/network/base_services.dart';
import 'package:net_knight/core/theme/nk_colors.dart';

import '../ai_generated_rules/widgets/sidebar_analyst.dart';
import 'models/reports_model_analyst.dart';
import 'services/reports_service_analyst.dart';
import 'widgets/threats_tab_content.dart';
import 'widgets/logs_tab_content.dart';

class ReportsScreenAnalyst extends StatefulWidget {
  const ReportsScreenAnalyst({super.key});

  @override
  State<ReportsScreenAnalyst> createState() => _ReportsScreenAnalystState();
}

class _ReportsScreenAnalystState extends State<ReportsScreenAnalyst> {
  final _service = ReportsServiceAnalyst();

  ReportTab _tab = ReportTab.threats;
  String _severityFilter = 'all severity';
  String _levelFilter = 'all levels';
  String _typeFilter = 'all types';
  String _dateFilter = 'last7days';

  List<ThreatModel> _threats = [];
  List<LogModel> _logs = [];
  bool _isLoading = true;
  String? _error;

  // بيانات اليوزر الحقيقية — بتيجي من TokenStorage بعد الـ login/verify
  String _username = 'User';
  String _role = '';
  String _initials = 'U';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadData();
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _threats = await _service.getThreats(dateFilter: _dateFilter);
      _logs = await _service.getLogs();
    } catch (e) {
      _error = 'Failed to load reports data';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportReport() async {
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: const Text('Choose format for last 7 days:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'csv'),
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'pdf'),
            child: const Text('PDF'),
          ),
        ],
      ),
    );

    if (format == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting $format for last 7 days...')),
    );

    try {
      final response = await BaseService.dio.post(
        '/staticfirewall/export',
        data: {
          'format': format,
          'days': 7,
          'type': _tab == ReportTab.threats ? 'threats' : 'logs',
          'severity': _severityFilter,
        },
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Download started')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export failed. Check backend.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          SidebarAnalyst(
            activeRoute: '/reports',
            username: _username,
            role: _role,
            initials: _initials,
          ),
          Expanded(
            child: Column(
              children: [
                const _TopBarAnalyst(title: 'Reports'),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTabsAndActions(),
                              const SizedBox(height: 16),
                              _buildSearchAndFilters(),
                              const SizedBox(height: 20),
                              _tab == ReportTab.threats
                                  ? ThreatsTabContent(
                                      threats: _threats,
                                      severityFilter: _severityFilter,
                                      dateFilter: _dateFilter,
                                    )
                                  : LogsTabContent(
                                      logs: _logs,
                                      levelFilter: _levelFilter,
                                      typeFilter: _typeFilter,
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

  Widget _buildTabsAndActions() {
    return Row(
      children: [
        _TabRadio(
          label: 'Threats',
          selected: _tab == ReportTab.threats,
          onTap: () => setState(() => _tab = ReportTab.threats),
        ),
        const SizedBox(width: 24),
        _TabRadio(
          label: 'Logs',
          selected: _tab == ReportTab.logs,
          onTap: () => setState(() => _tab = ReportTab.logs),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _exportReport,
          icon: const Icon(LucideIcons.download, size: 16),
          label: const Text('EXPORT'),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        SizedBox(
          width: 280,
          height: 40,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search.....',
              prefixIcon: const Icon(LucideIcons.search, size: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (_tab == ReportTab.threats) ...[
          _DropdownFilter(
            value: _severityFilter,
            options: const [
              'all severity',
              'critical',
              'high',
              'medium',
              'low',
            ],
            onChanged: (v) => setState(() => _severityFilter = v),
          ),
          const SizedBox(width: 8),
          _DateFilter(onChanged: (v) => setState(() => _dateFilter = v)),
        ] else ...[
          _DropdownFilter(
            value: _levelFilter,
            options: const ['all levels', 'INFO', 'ERROR', 'WARNING'],
            onChanged: (v) => setState(() => _levelFilter = v),
          ),
          const SizedBox(width: 8),
          _DropdownFilter(
            value: _typeFilter,
            options: const ['all types', 'Security', 'Firewall', 'AI Engine'],
            onChanged: (v) => setState(() => _typeFilter = v),
          ),
        ],
      ],
    );
  }
}

// Tab Radio
class _TabRadio extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabRadio({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.blue : Colors.black38,
                width: 2,
              ),
            ),
            child: selected
                ? const Center(
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: Colors.blue,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// Dropdown Filter
class _DropdownFilter extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _DropdownFilter({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1D242B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        dropdownColor: NKColors.cardDark,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        style: const TextStyle(color: NKColors.bg),
        underline: const SizedBox(),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }
}

// Date Filter
class _DateFilter extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _DateFilter({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF1D242B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 16, color: Colors.white),
          SizedBox(width: 6),
          Text('Last 7 days', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _TopBarAnalyst extends StatelessWidget {
  final String title;
  const _TopBarAnalyst({super.key, required this.title});

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
                  color: const Color(0xFF1D242B),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.bell, size: 22),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black12, height: 1),
        ],
      ),
    );
  }
}