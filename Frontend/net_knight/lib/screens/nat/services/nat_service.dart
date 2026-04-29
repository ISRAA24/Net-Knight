import 'package:dio/dio.dart';
import '../models/nat_model.dart';

class NatService {
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

  Future<String> previewNat(Map<String, dynamic> data) async {
    final response = await _dio.post('/preview_nat', data: data);
    final result = response.data;
    if (result['status'] == 'success') return result['command'] as String;
    return '';
  }

  Future<void> addMasquerade(MasqueradeModel model) async {
    await _dio.post('/staticfirewall/nat', data: model.toJson());
  }

  Future<void> addSourceNat(SourceNatModel model) async {
    await _dio.post('/staticfirewall/nat', data: model.toJson());
  }

  Future<void> addDestinationNat(DestinationNatModel model) async {
    await _dio.post('/staticfirewall/nat', data: model.toJson());
  }
}
