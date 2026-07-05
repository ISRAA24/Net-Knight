import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:net_knight/main.dart';
import 'package:net_knight/screens/admin/dashboard/widgets/sidebar.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html; // for web download

import 'models/report_model.dart';
import 'services/report_service.dart';
import 'widgets/threats_tab.dart';
import 'widgets/logs_tab.dart';

class ReportsScreenAdmin extends StatefulWidget {
  const ReportsScreenAdmin({super.key});

  @override
  State<ReportsScreenAdmin> createState() => _ReportsScreenAdminState();
}

class _ReportsScreenAdminState extends State<ReportsScreenAdmin> {
  final _service = ReportService();
  ReportTab _tab = ReportTab.threats;

  List<ThreatModel> _threats = [];
  List<LogModel> _logs = [];
  bool _isLoading = true;

  String _severityFilter = 'all';
  String _levelFilter = 'all';
  String _typeFilter = 'all';
  int _daysFilter = 7; // Default 7 days

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _threats = await _service.getThreats(days: _daysFilter);
      _logs = await _service.getLogs(days: _daysFilter);
    } catch (e) {
      debugPrint('Error loading reports: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // The backend currently ignores the "days" query param entirely, so we
  // filter on the client using each record's own date/createdAt value.
  bool _withinDays(String dateStr, int days) {
    if (dateStr.isEmpty) return true;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return true;
    return DateTime.now().difference(date).inDays <= days;
  }

  void _changeDaysFilter(int days) {
    setState(() => _daysFilter = days);
  }

  // ─── Manual CSV builder ────────────────────────────────────
  // We avoid the `csv` package here: its API changed across major versions
  // (ListToCsvConverter isn't guaranteed across pubspec ranges), and a
  // correctly-escaped CSV line is trivial to build by hand.
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
        title: const Text('Export Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('CSV'),
              onTap: () => Navigator.pop(context, 'csv'),
            ),
            ListTile(
              title: const Text('PDF'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
          ],
        ),
      ),
    );

    if (format == null) return;

    // NOTE: there is no '/reports/export' route on the backend at all, so
    // exporting is generated fully on the client from the data already
    // loaded/filtered on screen.
    try {
      final isThreats = _tab == ReportTab.threats;
      final headers = isThreats
          ? ['Attack Name', 'Attack Source', 'Severity', 'Status', 'Date']
          : ['Timestamp', 'Level', 'Source', 'Type', 'Message'];

      final rows = isThreats
          ? _filteredThreats
              .map((t) => [t.attackName, t.attackSource, t.severity, t.status, t.date])
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
            build: (context) => pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$filename downloaded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TopBar(title: 'Reports'),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
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
                                    ? ThreatsTab(
                                        threats: _filteredThreats,
                                        severityFilter: _severityFilter,
                                      )
                                    : LogsTab(
                                        logs: _filteredLogs,
                                        levelFilter: _levelFilter,
                                        typeFilter: _typeFilter,
                                      ),
                              ],
                            ),
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

  List<ThreatModel> get _filteredThreats {
    var filtered = _threats.where((t) => _withinDays(t.date, _daysFilter)).toList();
    if (_severityFilter != 'all') {
      filtered = filtered.where((t) => t.severity.toLowerCase() == _severityFilter).toList();
    }
    return filtered;
  }

  List<LogModel> get _filteredLogs {
    var filtered = _logs.where((l) => _withinDays(l.timestamp, _daysFilter)).toList();
    if (_levelFilter != 'all') {
      filtered = filtered.where((l) => l.level == _levelFilter).toList();
    }
    if (_typeFilter != 'all') {
      filtered = filtered.where((l) => l.type == _typeFilter).toList();
    }
    return filtered;
  }

  // The old hardcoded list ('Security', 'Firewall', 'AI Engine') never
  // matched real audit log actions (e.g. "Add Table", "System Login"...),
  // so the Type filter could never actually filter anything. We now build
  // the options from the real data instead.
  List<String> get _typeOptions => [
        'all',
        ..._logs.map((l) => l.type).where((t) => t.isNotEmpty).toSet(),
      ];

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
            options: const ['all', 'critical', 'high', 'medium', 'low'],
            onChanged: (v) => setState(() => _severityFilter = v),
          ),
          const SizedBox(width: 8),
          _DateFilter(currentDays: _daysFilter, onChanged: _changeDaysFilter),
        ] else ...[
          _DropdownFilter(
            value: _levelFilter,
            options: const ['all', 'INFO', 'ERROR', 'WARNING'],
            onChanged: (v) => setState(() => _levelFilter = v),
          ),
          const SizedBox(width: 8),
          _DropdownFilter(
            value: _typeOptions.contains(_typeFilter) ? _typeFilter : 'all',
            options: _typeOptions,
            onChanged: (v) => setState(() => _typeFilter = v),
          ),
          const SizedBox(width: 8),
          _DateFilter(currentDays: _daysFilter, onChanged: _changeDaysFilter),
        ],
      ],
    );
  }
}

// Tab Radio, DropdownFilter, DateFilter, TopBar...
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
        dropdownColor: Colors.white,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        style: const TextStyle(color: Colors.white),
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
        dropdownColor: Colors.white,
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

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.rajdhani(fontSize: 26, fontWeight: FontWeight.w500)),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.bell, size: 22),
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}