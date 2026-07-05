import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:net_knight/core/network/base_services.dart';

/// Fixed protocol order — لازم يطابق بالظبط PROTOCOL_BUCKETS في
/// Backend/src/sockets/pythonMetrics.socket.js (uppercase كلهم بما فيهم OTHER)
const List<String> kProtocolOrder = [
  'TLS', 'HTTP', 'FTP', 'SSH', 'TCP', 'UDP', 'ICMP', 'DNS', 'DHCP', 'OTHER'
];

class RealtimeMetrics {
  final double cpuUsage; // 0.0 -> 1.0 (للـ LinearProgressIndicator)
  final double memoryUsage; // 0.0 -> 1.0
  final String packetsPerSec;
  final String activeConnections;
  final Map<String, Map<String, num>> trafficChart;

  const RealtimeMetrics({
    this.cpuUsage = 0,
    this.memoryUsage = 0,
    this.packetsPerSec = '0',
    this.activeConnections = '0',
    this.trafficChart = const {},
  });

  factory RealtimeMetrics.fromJson(Map<String, dynamic> json) {
    final chart = <String, Map<String, num>>{};
    final rawChart = json['trafficChart'];
    if (rawChart is Map) {
      rawChart.forEach((k, v) {
        if (v is Map) {
          chart[k.toString()] = {
            'inbound': (v['inbound'] ?? 0) as num,
            'outbound': (v['outbound'] ?? 0) as num,
          };
        }
      });
    }
    return RealtimeMetrics(
      // ⚠️ الباك (dashboard.controller.js) بيبعت cpuUsage/memoryUsage كنسبة 0-100
      cpuUsage: ((json['cpuUsage'] ?? 0) as num).toDouble() / 100,
      memoryUsage: ((json['memoryUsage'] ?? 0) as num).toDouble() / 100,
      packetsPerSec: (json['packetsPerSecond'] ?? 0).toString(),
      activeConnections: (json['activeConnections'] ?? 0).toString(),
      trafficChart: chart,
    );
  }

  List<FlSpot> get outboundSpots => _spotsFor('outbound');
  List<FlSpot> get inboundSpots => _spotsFor('inbound');

  List<FlSpot> _spotsFor(String direction) {
    return List.generate(kProtocolOrder.length, (i) {
      final bucket = trafficChart[kProtocolOrder[i]];
      final value = (bucket?[direction] ?? 0).toDouble();
      return FlSpot(i.toDouble(), value);
    });
  }
}

class DashboardStatsRt {
  final int totalThreats;
  final int blockedAttacks;
  final int activeRules;
  final int pendingApprovals;

  const DashboardStatsRt({
    this.totalThreats = 0,
    this.blockedAttacks = 0,
    this.activeRules = 0,
    this.pendingApprovals = 0,
  });

  factory DashboardStatsRt.fromJson(Map<String, dynamic> j) => DashboardStatsRt(
        totalThreats: (j['totalThreats'] ?? 0) as int,
        blockedAttacks: (j['blockedAttacks'] ?? 0) as int,
        activeRules: (j['activeRules'] ?? 0) as int,
        pendingApprovals: (j['pendingApprovals'] ?? 0) as int,
      );
}

/// Singleton — Socket.IO واحد بس للتطبيق كله (Admin + Analyst)
/// بيسمع على 'dashboard:update' (metrics + stats) و 'notification:new'.
class DashboardSocketService extends ChangeNotifier {
  DashboardSocketService._();
  static final DashboardSocketService instance = DashboardSocketService._();

  IO.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  RealtimeMetrics metrics = const RealtimeMetrics();
  DashboardStatsRt stats = const DashboardStatsRt();

  /// بينادَى عند تشغيل الأبليكيشن (main.dart). آمن ينادَى أكتر من مرة.
  void connect() {
    if (_socket != null) return;

    _socket = IO.io(
      BaseService.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket] connected to ${BaseService.socketUrl}');
    });

    _socket!.on('dashboard:update', (data) {
      try {
        final map = Map<String, dynamic>.from(data as Map);
        if (map['realtime'] != null) {
          metrics = RealtimeMetrics.fromJson(
              Map<String, dynamic>.from(map['realtime'] as Map));
        }
        if (map['stats'] != null) {
          stats = DashboardStatsRt.fromJson(
              Map<String, dynamic>.from(map['stats'] as Map));
        }
        notifyListeners();
      } catch (e) {
        debugPrint('[Socket] dashboard:update parse error: $e');
      }
    });

    _socket!.on('notification:new', (data) {
      onNewNotification?.call();
    });

    _socket!.onDisconnect((_) => debugPrint('[Socket] disconnected'));
    _socket!.onConnectError((e) => debugPrint('[Socket] connect error: $e'));
    _socket!.onError((e) => debugPrint('[Socket] error: $e'));
  }

  /// Callback بيتنادى لما notification جديدة توصل (main.dart بيربطه بالـ Provider)
  void Function()? onNewNotification;

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}