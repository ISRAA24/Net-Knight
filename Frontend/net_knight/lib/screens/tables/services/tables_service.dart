import 'package:dio/dio.dart';
import '../models/table_model.dart';

class TablesService {
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

  Future<String> previewTable(TableModel table) async {
    final response = await _dio.post(
      '/preview_table',
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
