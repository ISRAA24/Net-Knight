import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/interface_model.dart';

class InterfacesService {
  final Dio _dio = BaseService.dio;

  // ─── جيب كل الـ interfaces ────────────────────────
  Future<List<InterfaceModel>> getInterfaces() async {
    final response = await _dio.get('/staticfirewall/interfaces');

    print('INTERFACES RESPONSE: ${response.data}'); // ← مؤقتاً

    final data = response.data['data'];

    if (data is List) {
      return data.map((e) => InterfaceModel.fromJson(e)).toList();
    } else if (data is Map && data['interfaces'] != null) {
      final List interfaces = data['interfaces'];
      return interfaces.map((e) => InterfaceModel.fromJson(e)).toList();
    }
    return [];
  }

  // ─── عدل الـ interface ────────────────────────────
  Future<void> editInterface(String realName, InterfaceModel updated) async {
    await _dio.put(
      '/staticfirewall/interfaces/$realName', // ← realName في الـ URL
      data: {
        'status': updated.status == 'connected' ? 'up' : 'down',
        'ipAddress': updated.ip,
      },
    );
  }

  // // ─── احذف الـ interface ───────────────────────────
  // Future<void> deleteInterface(String realName) async {
  //   await _dio.delete('/staticfirewall/interfaces/$realName');
  // }
}
