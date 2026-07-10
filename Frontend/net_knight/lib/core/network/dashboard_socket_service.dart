import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:net_knight/core/network/base_services.dart';

const List<String> kProtocolOrder = [
  'TLS',
  'HTTP',
  'FTP',
  'SSH',
  'TCP',
  'UDP',
  'ICMP',
  'DNS',
  'DHCP',
  'OTHER',
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

  factory DashboardStatsRt.fromJson(Map<String, dynamic> j) =>
      DashboardStatsRt(
        totalThreats: (j['totalThreats'] ?? 0) as int,
        blockedAttacks: (j['blockedAttacks'] ?? 0) as int,
        activeRules: (j['activeRules'] ?? 0) as int,
        pendingApprovals: (j['pendingApprovals'] ?? 0) as int,
      );
}

class TrendTracker {
  int? _previous;

  String update(int current) {
    final prev = _previous;
    _previous = current;

    if (prev == null || prev == current) return '— 0%';

    if (prev == 0) {
      return current > 0 ? '↗ 100%' : '— 0%';
    }

    final diff = current - prev;
    final pct = ((diff.abs() / prev) * 100).round();
    return diff > 0 ? '↗ $pct%' : '↘ $pct%';
  }
}

class DashboardSocketService extends ChangeNotifier {
  DashboardSocketService._();
  static final DashboardSocketService instance = DashboardSocketService._();

  IO.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  RealtimeMetrics metrics = const RealtimeMetrics();
  DashboardStatsRt stats = const DashboardStatsRt();

  DateTime? _lastRealtimeUpdateAt;
  static const _agentTimeout = Duration(seconds: 10);

  bool get isAgentAlive =>
      _lastRealtimeUpdateAt != null &&
      DateTime.now().difference(_lastRealtimeUpdateAt!) < _agentTimeout;

  final _totalThreatsTrend = TrendTracker();
  final _blockedAttacksTrend = TrendTracker();
  final _activeRulesTrend = TrendTracker();
  final _pendingApprovalsTrend = TrendTracker();

  String totalThreatsTrend = '— 0%';
  String blockedAttacksTrend = '— 0%';
  String activeRulesTrend = '— 0%';
  String pendingApprovalsTrend = '— 0%';

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
            Map<String, dynamic>.from(map['realtime'] as Map),
          );
          _lastRealtimeUpdateAt = DateTime.now();
        }
        if (map['stats'] != null) {
          final newStats = DashboardStatsRt.fromJson(
            Map<String, dynamic>.from(map['stats'] as Map),
          );

          totalThreatsTrend = _totalThreatsTrend.update(newStats.totalThreats);
          blockedAttacksTrend =
              _blockedAttacksTrend.update(newStats.blockedAttacks);
          activeRulesTrend = _activeRulesTrend.update(newStats.activeRules);
          pendingApprovalsTrend =
              _pendingApprovalsTrend.update(newStats.pendingApprovals);

          stats = newStats;
        }
        notifyListeners();
      } catch (e) {
        debugPrint('[Socket] dashboard:update parse error: $e');
      }
    });

    _socket!.on('notification:new', (data) {
      onNewNotification?.call();
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket] disconnected');
    });
    _socket!.onConnectError((e) => debugPrint('[Socket] connect error: $e'));
    _socket!.onError((e) => debugPrint('[Socket] error: $e'));
  }

  void Function()? onNewNotification;

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}