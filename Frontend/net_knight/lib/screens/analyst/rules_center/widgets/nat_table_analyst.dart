import 'package:flutter/material.dart';
import '../models/rules_center_model_analyst.dart';
import 'table_primitives_analyst.dart';

class NatTableAnalyst extends StatelessWidget {
  const NatTableAnalyst({super.key, required this.rows});
  final List<NatRuleModelAnalyst> rows;

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
                  THAnalyst('Interface', flex: 2),
                  THDAnalyst(),
                  THAnalyst('Translated IP/Dest IP', flex: 3),
                  THDAnalyst(),
                  THAnalyst('Ext Port', flex: 2),
                  THDAnalyst(),
                  THAnalyst('Int Port', flex: 2),
                  THDAnalyst(),
                  THAnalyst('NAT Type', flex: 2),
                  THDAnalyst(),
                  THAnalyst('Created', flex: 2),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black),

            // ── Rows ──
            rows.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No NAT rules match your search.',
                      style: TextStyle(color: Colors.black45),
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
                      final type = rule.natType.toLowerCase();
                      final displayIp =
                          (type == 'destination' || type == 'dnat')
                          ? (rule.destIp.isEmpty ? '—' : rule.destIp)
                          : (type == 'source' ||
                                type == 'snat' ||
                                type == 'source nat')
                          ? (rule.newSourceIp.isEmpty ? '—' : rule.newSourceIp)
                          : '—';
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TDWidgetAnalyst(
                              flex: 2,
                              child: ReadOnlyToggleAnalyst(
                                enabled: rule.enabled,
                              ),
                            ),
                            const VDAnalyst(),
                            TDAnalyst(rule.sourceIp, flex: 3),
                            const VDAnalyst(),
                            TDAnalyst(rule.interfaceName, flex: 2),
                            const VDAnalyst(),
                            TDAnalyst(rule.destIp, flex: 3),
                            const VDAnalyst(),
                            TDAnalyst(displayIp, flex: 3),
                            const VDAnalyst(),
                            TDAnalyst(rule.extPort, flex: 2),
                            const VDAnalyst(),
                            TDAnalyst(rule.intPort, flex: 2),
                            const VDAnalyst(),
                            TDWidgetAnalyst(
                              flex: 2,
                              child: Text(
                                rule.natType,
                                style: TextStyle(
                                  color: rule.natTypeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const VDAnalyst(),
                            TDAnalyst(rule.created, flex: 2, size: 15),
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
