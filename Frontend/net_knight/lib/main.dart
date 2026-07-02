import 'package:flutter/material.dart';
import 'package:net_knight/core/network/base_services.dart';
import 'package:net_knight/screens/admin/interfaces/interfaces_screen.dart';
import 'package:net_knight/screens/admin/nat/nat_screen.dart';
import 'package:net_knight/screens/admin/rules/rules_screen.dart';
import 'package:net_knight/screens/admin/splash/splash_screen.dart';
import 'package:net_knight/screens/admin/user_management/user_management_screen.dart';
import 'package:net_knight/screens/admin/rule_management/rule_management_screen.dart';
import 'package:net_knight/screens/admin/log_in/log_in_screen.dart';
import 'package:net_knight/screens/admin/sign_up/sign_up_screen.dart';
import 'package:net_knight/screens/admin/verification/verification_screen.dart';
import 'package:net_knight/screens/admin/dashboard/dashboard_screen.dart';
import 'package:net_knight/screens/admin/tables/tables_screen.dart';
import 'package:net_knight/screens/admin/chains/chains_screen.dart';
import 'package:net_knight/screens/analyst/ai_generated_rules/ai_generated_rules_screen_analyst.dart';
import 'package:net_knight/screens/analyst/statistics/statistics_screen_analyst.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BaseService.init();
  runApp(const NetKnight());
}

class NetKnight extends StatelessWidget {
  const NetKnight({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetKnight',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LogInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/tables': (context) => const TablesScreen(),
        '/chains': (context) => const ChainsScreen(),
        '/rules': (context) => const RulesScreen(),
        '/interfaces': (context) => const InterfacesScreen(),
        '/nat': (context) => const NATScreen(),
        '/users': (context) => const UserManagementScreen(),
        '/rules-management': (context) => const RuleManagementScreen(),
        '/ai-rules': (context) => const AiGeneratedRulesScreenAnalyst(),
        '/statistics': (context) => const StatisticsScreenAnalyst(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/verification') {
          final args = settings.arguments as VerificationArgs?;
          return MaterialPageRoute(
            builder: (_) => VerificationScreen(
              args:
                  args ?? const VerificationArgs(email: '', isFromLogin: false),
            ),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
