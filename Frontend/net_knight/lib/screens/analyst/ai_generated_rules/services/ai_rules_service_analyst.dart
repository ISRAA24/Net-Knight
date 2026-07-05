import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/ai_rule_model_analyst.dart';

class AiRulesServiceAnalyst {
  final Dio _dio = BaseService.dio;

  Future<List<AiRuleModelAnalyst>> getRules() async {
    final response = await _dio.get('/ai/rules');
    final List data = response.data['data'];
    return data.map((e) => AiRuleModelAnalyst.fromJson(e)).toList();
  }
}