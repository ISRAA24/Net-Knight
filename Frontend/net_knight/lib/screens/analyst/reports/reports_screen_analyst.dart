import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:net_knight/core/network/base_services.dart';
import 'package:net_knight/core/theme/nk_colors.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

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
  int _daysFilter = 7;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<ThreatModel> _threats = [];
  List<LogModel> _logs = [];
  bool _isLoading = true;
  String? _error;

  String _username = 'User';
  String _role = '';
  String _initials = 'U';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _threats = await _service.getThreats();
      _logs = await _service.getLogs();
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load reports data');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _withinDays(String dateStr, int days) {
    if (dateStr.isEmpty) return true;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return true;
    return DateTime.now().difference(date).inDays <= days;
  }

  List<ThreatModel> get _filteredThreats {
    var filtered = _threats
        .where((t) => _withinDays(t.date, _daysFilter))
        .toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (t) =>
                t.attackName.toLowerCase().contains(q) ||
                t.attackSource.toLowerCase().contains(q),
          )
          .toList();
    }
    return filtered;
  }

  List<LogModel> get _filteredLogs {
    var filtered = _logs
        .where((l) => _withinDays(l.timestamp, _daysFilter))
        .toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (l) =>
                l.message.toLowerCase().contains(q) ||
                l.source.toLowerCase().contains(q) ||
                l.type.toLowerCase().contains(q),
          )
          .toList();
    }
    return filtered;
  }

  List<String> get _typeOptions => [
    'all types',
    ..._logs.map((l) => l.type).where((t) => t.isNotEmpty).toSet(),
  ];

  // ─── Manual CSV builder ────────────────────────────────────

  String _escapeCsvField(String field) {
    final needsQuoting =
        field.contains(',') || field.contains('"') || field.contains('\n');
    if (!needsQuoting) return field;
    return '"${field.replaceAll('"', '""')}"';
  }

  String _buildCsv(List<String> headers, List<List<String>> rows) {
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_escapeCsvField).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsvField).join(','));
    }
    return buffer.toString();
  }

  Future<void> _exportReport() async {
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: const Text('Choose format:'),
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

    try {
      final isThreats = _tab == ReportTab.threats;
      final headers = isThreats
          ? ['Attack Name', 'Attack Source', 'Severity', 'Status', 'Date']
          : ['Timestamp', 'Level', 'Source', 'Type', 'Message'];

      final rows = isThreats
          ? _filteredThreats
                .map(
                  (t) => [
                    t.attackName,
                    t.attackSource,
                    t.severity,
                    t.status,
                    t.date,
                  ],
                )
                .toList()
          : _filteredLogs
                .map((l) => [l.timestamp, l.level, l.source, l.type, l.message])
                .toList();

      Uint8List bytes;
      String filename;

      if (format == 'csv') {
        final csvData = _buildCsv(headers, rows);
        bytes = Uint8List.fromList(utf8.encode(csvData));
        filename = 'report.csv';
      } else {
        final doc = pw.Document();
        doc.addPage(
          pw.Page(
            build: (context) =>
                pw.TableHelper.fromTextArray(headers: headers, data: rows),
          ),
        );
        bytes = await doc.save();
        filename = 'report.pdf';
      }

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', filename);
        anchor.click();
        html.Url.revokeObjectUrl(url);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$filename downloaded')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
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
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                    threats: _filteredThreats,
                    severityFilter: _severityFilter,
                    dateFilter: _daysFilter.toString(),
                  )
                : LogsTabContent(
                    logs: _filteredLogs,
                    levelFilter: _levelFilter,
                    typeFilter: _typeFilter,
                  ),
          ],
        ),
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
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
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
          _DateFilter(
            currentDays: _daysFilter,
            onChanged: (v) => setState(() => _daysFilter = v),
          ),
        ] else ...[
          _DropdownFilter(
            value: _levelFilter,
            options: const ['all levels', 'INFO', 'ERROR', 'WARNING'],
            onChanged: (v) => setState(() => _levelFilter = v),
          ),
          const SizedBox(width: 8),
          _DropdownFilter(
            value: _typeOptions.contains(_typeFilter)
                ? _typeFilter
                : 'all types',
            options: _typeOptions,
            onChanged: (v) => setState(() => _typeFilter = v),
          ),
          const SizedBox(width: 8),
          _DateFilter(
            currentDays: _daysFilter,
            onChanged: (v) => setState(() => _daysFilter = v),
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
        value: options.contains(value) ? value : options.first,
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

class _DateFilter extends StatelessWidget {
  final int currentDays;
  final ValueChanged<int> onChanged;
  const _DateFilter({required this.currentDays, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF1D242B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: currentDays,
        dropdownColor: NKColors.cardDark,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        style: const TextStyle(color: Colors.white),
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 1, child: Text('Last 1 day')),
          DropdownMenuItem(value: 7, child: Text('Last 7 days')),
          DropdownMenuItem(value: 14, child: Text('Last 14 days')),
        ],
        onChanged: (v) => onChanged(v!),
      ),
    );
  }
}

class _TopBarAnalyst extends StatelessWidget {
  const _TopBarAnalyst({required this.title});
  final String title;

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
