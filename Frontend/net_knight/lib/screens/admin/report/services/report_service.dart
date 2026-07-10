import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/report_model.dart';

class ReportService {
  Future<List<ThreatModel>> getThreats({int days = 7}) async {
    try {
      final response = await BaseService.dio.get('/ai/threats', queryParameters: {'days': days});
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

  Future<List<LogModel>> getLogs({int days = 7}) async {
    try {
      final response = await BaseService.dio.get('/staticfirewall/logs', queryParameters: {'days': days});
      final data = response.data['data'];
      if (data is List) {
        return data.map((e) => LogModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching logs: $e');
      return [];
    }
  }

  Future<Response> exportReport({int days = 7, required String format}) async {
    try {
      final response = await BaseService.dio.get(
        '/reports/export',
        queryParameters: {'days': days, 'format': format},
        options: Options(responseType: ResponseType.bytes),
      );
      return response;
    } catch (e) {
      print('Export error: $e');
      rethrow;
    }
  }
}