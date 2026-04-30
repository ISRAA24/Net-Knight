import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/nat_model.dart';

class NatService {
  final Dio _dio = BaseService.dio;

  // ─── Get Interfaces from API ──────────────────────────
  Future<List<String>> getInterfaces() async {
    final response = await _dio.get('/staticfirewall/interfaces');
    final List data = response.data['data'];
    return data.map((e) => e['name'].toString()).toList();
  }

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
