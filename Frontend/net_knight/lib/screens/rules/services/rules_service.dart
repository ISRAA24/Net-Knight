import 'package:dio/dio.dart';
import '../models/rule_model.dart';

class RulesService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://paddling-levitator-impromptu.ngrok-free.dev/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ),
  );

  Future<List<String>> getTables() async {
    final response = await _dio.get('/staticfirewall/tables');
    final List data = response.data;
    return data.map((e) => e['name'].toString()).toList();
  }

  Future<List<String>> getChains(String tableName) async {
    final response = await _dio.get('/staticfirewall/chains/$tableName');
    final List data = response.data;
    return data.map((e) => e['name'].toString()).toList();
  }

  Future<String> previewRule(RuleModel rule) async {
    final response = await _dio.post(
      '/preview_rule',
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
