import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:net_knight/core/network/base_services.dart';
import 'package:net_knight/core/network/dashboard_socket_service.dart';
import 'package:net_knight/screens/shared/notification/services/notification_service.dart';
import 'package:net_knight/screens/admin/ai_generated_rules_admin/ai_generated_rules_screen.dart';
import 'package:net_knight/screens/admin/interfaces/interfaces_screen.dart';
import 'package:net_knight/screens/admin/nat/nat_screen.dart';
import 'package:net_knight/screens/admin/report/reports_screen.dart';
import 'package:net_knight/screens/admin/rules/rules_screen.dart';
import 'package:net_knight/screens/admin/splash/splash_screen.dart';
import 'package:net_knight/screens/admin/user_management/user_management_screen.dart';
import 'package:net_knight/screens/admin/rule_management/rule_management_screen.dart';
import 'package:net_knight/screens/admin/log_in/log_in_screen.dart';
import 'package:net_knight/screens/admin/sign_up/sign_up_screen.dart';
import 'package:net_knight/screens/admin/verification/verification_screen.dart';
import 'package:net_knight/screens/admin/dashboard/statistics_screen.dart';
import 'package:net_knight/screens/admin/tables/tables_screen.dart';
import 'package:net_knight/screens/admin/chains/chains_screen.dart';
import 'package:net_knight/screens/analyst/ai_generated_rules/ai_generated_rules_screen_analyst.dart';
import 'package:net_knight/screens/analyst/reports/reports_screen_analyst.dart';
import 'package:net_knight/screens/analyst/rules_center/rules_center_screen_analyst.dart';
import 'package:net_knight/screens/analyst/statistics/statistics_screen_analyst.dart';
import 'package:net_knight/screens/shared/notification/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BaseService.init();
  runApp(const NetKnight());
}

class NetKnight extends StatefulWidget {
  const NetKnight({super.key});

  @override
  State<NetKnight> createState() => _NetKnightState();
}

class _NetKnightState extends State<NetKnight> {
  final _notificationProvider = NotificationProvider();
  final _socket = DashboardSocketService.instance;

  @override
  void initState() {
    super.initState();

    _socket.connect();

    _socket.onNewNotification = () {
      _notificationProvider.updateUnreadCount(
        _notificationProvider.unreadCount + 1,
      );
    };

    _loadInitialUnreadCount();
  }

  Future<void> _loadInitialUnreadCount() async {
    final count = await NotificationService().getUnreadCount();
    _notificationProvider.updateUnreadCount(count);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _notificationProvider,
      child: MaterialApp(
        title: 'NetKnight',
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LogInScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/dashboard': (context) => const StatisticsScreenAdmin(),
          '/tables': (context) => const TablesScreen(),
          '/chains': (context) => const ChainsScreen(),
          '/rules': (context) => const RulesScreen(),
          '/interfaces': (context) => const InterfacesScreen(),
          '/nat': (context) => const NATScreen(),
          '/users': (context) => const UserManagementScreen(),
          '/rules-management': (context) => const RuleManagementScreen(),
          '/ai-rules': (context) => const AiGeneratedRulesScreenAnalyst(),
          '/statistics': (context) => const StatisticsScreenAnalyst(),
          '/reports': (context) => const ReportsScreenAnalyst(),
          '/rules-center': (context) => const RulesCenterScreenAnalyst(),
          '/reports-admin': (context) => const ReportsScreenAdmin(),
          '/ai-rules-admin': (context) => const AiGeneratedRulesScreenAdmin(),
          '/notifications': (context) => const NotificationsScreenAdmin(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/verification') {
            final args = settings.arguments as VerificationArgs?;
            return MaterialPageRoute(
              builder: (_) => VerificationScreen(
                args: args ?? const VerificationArgs(email: '', isFromLogin: false),
              ),
              settings: settings,
            );
          }
          return null;
        },
      ),
    );
  }
}

// Notification Provider
class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  void updateUnreadCount(int count) {
    _unreadCount = count < 0 ? 0 : count;
    notifyListeners();
  }
}