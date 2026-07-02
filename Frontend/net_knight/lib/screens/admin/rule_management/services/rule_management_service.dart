import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/rule_model.dart';

class RuleManagementService {
  final Dio _dio = BaseService.dio;

  Future<Map<String, dynamic>> getAllRules() async {
    final response = await _dio.get('/staticfirewall/allRules');
    final data = response.data['data'];
    return {
      'staticRules': (data['staticRules'] as List)
          .map((e) => RuleModel.fromJson(e))
          .toList(),
      'natRules': (data['natRules'] as List)
          .map((e) => NatRuleModel.fromJson(e))
          .toList(),
    };
  }

  Future<void> toggleRule(String id) async {
    await _dio.patch('/staticfirewall/rules/$id/toggle');
  }

  Future<void> deleteRule(String id) async {
    await _dio.delete('/staticfirewall/rules/$id');
  }
}