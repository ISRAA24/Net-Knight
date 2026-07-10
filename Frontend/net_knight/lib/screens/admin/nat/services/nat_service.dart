import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/nat_model.dart';

class NatService {
  final Dio _dio = BaseService.dio;

  Future<List<String>> getInterfaces() async {
    final response = await _dio.get('/staticfirewall/interfaces');
    final data = response.data['data'];

    List raw;
    if (data is List) {
      raw = data;
    } else if (data is Map && data['interfaces'] is List) {
      raw = data['interfaces'] as List;
    } else {
      raw = const [];
    }

    return raw
        .map((e) {
          if (e is Map) {
            return e['name'] ?? e['logicalName'] ?? e['realName'];
          }
          return e;
        })
        .where((e) => e != null)
        .map((e) => e.toString())
        .toList();
  }

  Future<String> previewNat(Map<String, dynamic> data) async {
    final response = await _dio
        .post('${BaseService.previewBaseUrl}/preview_nat', data: data);
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