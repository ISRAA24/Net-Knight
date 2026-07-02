import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';

class DashboardService {
  final Dio _dio = BaseService.dio;

  Future<Map<String, dynamic>> getStats() async {
    final response = await _dio.get('/stats');
    return response.data;
  }

  Future<List<dynamic>> getThreats() async {
    final response = await _dio.get('/threats');
    return response.data;
  }

  Future<Map<String, dynamic>> getSystemStatus() async {
    final response = await _dio.get('/system/status');
    return response.data;
  }

  Future<List<dynamic>> getNetworkTraffic() async {
    final response = await _dio.get('/network/traffic');
    return response.data;
  }

  Future<void> blockThreat(String ip) async {
    await _dio.post('/threats/block', data: {'ip': ip});
  }
}
