import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/rules_center_model_analyst.dart';

class RulesCenterServiceAnalyst {
  final Dio _dio = BaseService.dio;

  Future<List<FirewallRuleModelAnalyst>> getFirewallRules() async {
    final response = await _dio.get('/staticfirewall/allRules');
    final List data = response.data['data'] ?? [];
    return data.map((e) => FirewallRuleModelAnalyst.fromJson(e)).toList();
  }

  Future<List<NatRuleModelAnalyst>> getNatRules() async {
    final response = await _dio.get('/staticfirewall/nat');
    final List data = response.data['data'] ?? [];
    return data.map((e) => NatRuleModelAnalyst.fromJson(e)).toList();
  }
}