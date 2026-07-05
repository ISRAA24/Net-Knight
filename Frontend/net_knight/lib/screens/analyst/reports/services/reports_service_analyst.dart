import 'package:net_knight/core/network/base_services.dart';
import '../models/reports_model_analyst.dart';

class ReportsServiceAnalyst {
  Future<List<ThreatModel>> getThreats({String dateFilter = 'last7days'}) async {
    try {
      final response = await BaseService.dio.get(
        '/ai/threats',
        queryParameters: {'dateFilter': dateFilter},
      );
      final data = response.data['data'];
      if (data is List) {
        return data.map((e) => ThreatModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching threats: $e');
      return [];
    }
  }

  Future<List<LogModel>> getLogs() async {
    try {
      final response = await BaseService.dio.get('/staticfirewall/logs');
      final data = response.data['data'];
      if (data is List) {
        return data.map((e) => LogModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching audit logs: $e');
      return [];
    }
  }
}