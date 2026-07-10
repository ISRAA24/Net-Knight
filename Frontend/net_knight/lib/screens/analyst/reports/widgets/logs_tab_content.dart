import 'package:flutter/material.dart';
import '../models/reports_model_analyst.dart';
import 'table_helpers.dart';

class LogsTabContent extends StatelessWidget {
  final List<LogModel> logs;
  final String levelFilter;
  final String typeFilter;

  const LogsTabContent({super.key, required this.logs, required this.levelFilter, required this.typeFilter});

  @override
  Widget build(BuildContext context) {
    final filtered = logs.where((log) {
      final levelMatch = levelFilter == 'all levels' || log.level == levelFilter;
      final typeMatch = typeFilter == 'all types' || log.type == typeFilter;
      return levelMatch && typeMatch;
    }).toList();

    return buildDataTable(
      headers: ['Timestamp', 'Level', 'Source', 'Type', 'Message', 'IP'],
      rows: filtered.map((log) => [log.timestamp, log.level, log.source, log.type, log.message, log.ip]).toList(),
      flexes: [2, 2, 2, 2, 5, 2],
    );
  }
}