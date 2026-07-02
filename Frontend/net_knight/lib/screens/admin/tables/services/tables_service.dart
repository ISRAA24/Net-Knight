import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/table_model.dart';

class TablesService {
  final Dio _dio = BaseService.dio;

  Future<String> previewTable(TableModel table) async {
    final response = await _dio.post(
      '${BaseService.previewBaseUrl}/preview_table',
      data: {
        'table_name': table.name,
        'family': table.family,
      },
    );
    final data = response.data;
    if (data['status'] == 'success') return data['command'] as String;
    return '';
  }

  Future<void> addTable(TableModel table) async {
    await _dio.post(
      '/staticfirewall/tables',
      data: table.toJson(),
    );
  }
}
