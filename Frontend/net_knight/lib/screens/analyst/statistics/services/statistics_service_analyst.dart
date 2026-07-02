import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/statistics_model_analyst.dart';

class StatisticsServiceAnalyst {
  final Dio _dio = BaseService.dio;

  Future<StatisticsSummaryAnalyst> getStatistics() async {
    final response = await _dio.get('/statistics');
    return StatisticsSummaryAnalyst.fromJson(response.data['data']);
  }
}