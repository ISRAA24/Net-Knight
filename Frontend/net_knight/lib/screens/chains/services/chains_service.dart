import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/chain_model.dart';
import '../../../core/models/table_entry.dart';

class ChainsService {
  final Dio _dio = BaseService.dio;

  // ← بيرجع TableEntry عشان نعرف الـ family
  Future<List<TableEntry>> getTables() async {
    final response = await _dio.get('/staticfirewall/tables');
    final List data = response.data['data'];
    return data.map((e) => TableEntry.fromJson(e)).toList();
  }

  Future<String> previewChain(ChainModel chain) async {
    final response = await _dio.post(
      '${BaseService.previewBaseUrl}/preview_chain',
      data: {
        'family': chain.family, // ← الـ family من الـ table
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
