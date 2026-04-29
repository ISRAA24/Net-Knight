import 'package:dio/dio.dart';
import '../models/chain_model.dart';

class ChainsService {
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

  Future<String> previewChain(ChainModel chain) async {
    final response = await _dio.post(
      '/preview_chain',
      data: {
        'family': 'ip',
        'table_name': chain.tableName,
        'chain_name': chain.chainName,
        'hook': chain.hook,
        'priority': chain.priority,
        'policy': chain.policy,
        'chain_type': chain.type,
      },
    );
    final data = response.data;
    if (data['status'] == 'success') return data['command'] as String;
    return '';
  }

  Future<void> addChain(ChainModel chain) async {
    await _dio.post(
      '/staticfirewall/chains',
      data: chain.toJson(),
    );
  }
}
