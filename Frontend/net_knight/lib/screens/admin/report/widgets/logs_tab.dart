import 'package:flutter/material.dart';
import '../models/report_model.dart';

class LogsTab extends StatelessWidget {
  final List<LogModel> logs;
  final String levelFilter;
  final String typeFilter;

  const LogsTab({super.key, required this.logs, required this.levelFilter, required this.typeFilter});

  List<LogModel> get _filtered {
    var filtered = logs;
    if (levelFilter != 'all') {
      filtered = filtered.where((l) => l.level == levelFilter).toList();
    }
    if (typeFilter != 'all') {
      filtered = filtered.where((l) => l.type == typeFilter).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              color: const Color(0xFFF9FAFB),
              child: const Row(
                children: [
                  _TH('Timestamp', flex: 2),
                  _TH('Level', flex: 2),
                  _TH('Source', flex: 2),
                  _TH('Type', flex: 2),
                  _TH('Message', flex: 5),
                  _TH('IP', flex: 2),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black),
            if (_filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('No logs match the selected filters.'),
              )
            else
              ..._filtered.map((r) => Column(
                children: [
                  _LogRowWidget(r),
                  const Divider(height: 1, color: Colors.black),
                ],
              )),
          ],
        ),
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    ),
  );
}

class _LogRowWidget extends StatelessWidget {
  final LogModel row;
  const _LogRowWidget(this.row);

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TD(row.timestamp, flex: 2),
        _VDivider(),
        _TD(row.level, flex: 2),
        _VDivider(),
        _TD(row.source, flex: 2),
        _VDivider(),
        _TD(row.type, flex: 2),
        _VDivider(),
        _TD(row.message, flex: 5),
        _VDivider(),
        _TD(row.ip, flex: 2),
      ],
    ),
  );
}

class _TD extends StatelessWidget {
  final String text;
  final int flex;
  const _TD(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Text(text),
    ),
  );
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, color: Colors.black);
}