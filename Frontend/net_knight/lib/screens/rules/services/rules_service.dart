import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/rule_model.dart';

class RulesService {
  final Dio _dio = BaseService.dio;

  Future<List<String>> getTables() async {
    final response = await _dio.get('/staticfirewall/tables');
    final List data = response.data['data'];
    return data.map((e) => e['name'].toString()).toList();
  }

  Future<List<String>> getChains() async {
    final response = await _dio.get('/staticfirewall/chains');
    final List data = response.data['data'];
    return data.map((e) => e['name'].toString()).toList();
  }

  // ← Interfaces من API
  Future<List<String>> getInterfaces() async {
    final response = await _dio.get('/staticfirewall/interfaces');
    final List data = response.data['data']['interfaces'];
    return data.map((e) => e['name'].toString()).toList();
  }

  Future<String> previewRule(RuleModel rule) async {
    final response = await _dio.post(
      '${BaseService.previewBaseUrl}/preview_rule',
      data: {
        'family': 'ip',
        'table_name': rule.tableName,
        'chain_name': rule.chainName,
        'ip_src': rule.ipSource,
        'ip_dest': rule.ipDestination,
        'port_dest': rule.portDestination,
        'interface': rule.interface,
        'protocol': rule.protocol,
        'action': rule.action,
      },
    );
    final data = response.data;
    if (data['status'] == 'success') return data['command'] as String;
    return '';
  }

  Future<void> addRule(RuleModel rule) async {
    await _dio.post(
      '/staticfirewall/rules',
      data: rule.toJson(),
    );
  }
}
