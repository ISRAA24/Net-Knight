import 'package:net_knight/core/network/base_services.dart';
import '../models/reports_model_analyst.dart';

class ReportsServiceAnalyst {
  Future<List<ThreatModel>> getThreats({String dateFilter = 'last7days'}) async {
    try {
      final response = await BaseService.dio.get('/staticfirewall/threats', queryParameters: {'dateFilter': dateFilter});
      if (response.data is List) {
        return (response.data as List).map((e) => ThreatModel.fromJson(e)).toList();
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
      if (response.data is List) {
        return (response.data as List).map((e) => LogModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching audit logs: $e');
      return [];
    }
  }
}