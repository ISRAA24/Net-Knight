import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/interface_model.dart';

class InterfacesService {
  final Dio _dio = BaseService.dio;

  // ─── Get interfaces ────────────────────────
  Future<List<InterfaceModel>> getInterfaces() async {
    final response = await _dio.get('/staticfirewall/interfaces');
    final data = response.data['data'];

    if (data is List) {
      return data.map((e) => InterfaceModel.fromJson(e)).toList();
    } else if (data is Map && data['interfaces'] != null) {
      final List interfaces = data['interfaces'];
      return interfaces.map((e) => InterfaceModel.fromJson(e)).toList();
    }
    return [];
  }

  // ─── Edit interface ────────────────────────────
  // ⚠️ FIX: this previously only sent `status` and `ipAddress`, so editing
  // the Logical Name in EditInterfaceDialog silently did nothing — the
  // dialog closed as if it succeeded, but the new name was never sent to
  // the backend and was lost. We now include `logicalName` in the request
  // body as well. (Note: this still requires the corresponding backend
  // route/controller to actually persist `logicalName` for the change to
  // take effect end-to-end.)
  Future<void> editInterface(String realName, InterfaceModel updated) async {
    await _dio.put(
      '/staticfirewall/interfaces/$realName',
      data: {
        'logicalName': updated.logicalName,
        'status': updated.status == 'connected' ? 'up' : 'down',
        'ipAddress': updated.ip,
      },
    );
  }
}