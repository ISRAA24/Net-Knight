import 'package:flutter/material.dart';
import '../models/rules_center_model_analyst.dart';
import 'table_primitives_analyst.dart';

class FirewallTableAnalyst extends StatelessWidget {
  const FirewallTableAnalyst({super.key, required this.rows});
  final List<FirewallRuleModelAnalyst> rows;

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
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              color: Colors.white,
              child: const Row(
                children: [
                  THAnalyst('Status', flex: 2),
                  THDAnalyst(),
                  THAnalyst('Source IP', flex: 3),
                  THDAnalyst(),
                  THAnalyst('Destination', flex: 3),
                  THDAnalyst(),
                  THAnalyst('Port', flex: 2),
                  THDAnalyst(),
                  THAnalyst('Protocol', flex: 2),
                  THDAnalyst(),
                  THAnalyst('Action', flex: 2),
                  THDAnalyst(),
                  THAnalyst('Created', flex: 2),
                  THDAnalyst(),
                  THAnalyst('Origin', flex: 2),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black),

            // ── Rows ──
            rows.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No rules match your search.',
                        style: TextStyle(color: Colors.black45),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.black),
                    itemBuilder: (_, i) {
                      final rule = rows[i];
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TDWidgetAnalyst(
                              flex: 2,
                              child: ReadOnlyToggleAnalyst(
                                  enabled: rule.enabled),
                            ),
                            const VDAnalyst(),
                            TDAnalyst(rule.sourceIp, flex: 3),
                            const VDAnalyst(),
                            TDAnalyst(rule.destination, flex: 3),
                            const VDAnalyst(),
                            TDAnalyst(rule.port, flex: 2),
                            const VDAnalyst(),
                            TDAnalyst(rule.protocol, flex: 2),
                            const VDAnalyst(),
                            TDWidgetAnalyst(
                              flex: 2,
                              child: Text(
                                rule.action,
                                style: TextStyle(
                                  color: rule.actionColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const VDAnalyst(),
                            TDAnalyst(rule.created, flex: 2, size: 15),
                            const VDAnalyst(),
                            TDAnalyst(rule.origin, flex: 2, size: 15),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}