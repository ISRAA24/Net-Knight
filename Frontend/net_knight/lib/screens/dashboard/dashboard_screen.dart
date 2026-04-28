import 'package:flutter/material.dart';
import '../../core/theme/nk_colors.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';
import 'widgets/stats_grid.dart';
import 'widgets/chart_section.dart';
import 'widgets/system_status_card.dart';
import 'widgets/threat_alerts_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NKColors.bg,
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        StatsGrid(),
                        SizedBox(height: 20),
                        ChartSection(),
                        SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: SystemStatusCard()),
                            SizedBox(width: 12),
                            Expanded(child: ThreatAlertsCard()),
                          ],
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
}
