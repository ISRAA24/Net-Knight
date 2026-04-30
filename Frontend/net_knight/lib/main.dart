import 'package:flutter/material.dart';
import 'package:net_knight/screens/interfaces/interfaces_screen.dart';
import 'package:net_knight/screens/nat/nat_screen.dart';
import 'package:net_knight/screens/rules/rules_screen.dart';
import 'package:net_knight/screens/user_management/user_management_screen.dart';
import 'screens/log_in/log_in_screen.dart';
import 'screens/sign_up/sign_up_screen.dart';
import 'screens/verification/verification_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/tables/tables_screen.dart';
import 'screens/chains/chains_screen.dart';

void main() => runApp(const NetKnight());

class NetKnight extends StatelessWidget {
  const NetKnight({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetKnight',
      debugShowCheckedModeBanner: false,
      home: const LogInScreen(),
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
