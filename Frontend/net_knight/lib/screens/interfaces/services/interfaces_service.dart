import 'package:dio/dio.dart';
import '../models/interface_model.dart';

class InterfacesService {
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

  Future<List<InterfaceModel>> getInterfaces() async {
    final response = await _dio.get('/staticfirewall/interfaces');
    final List data = response.data;
    return data.map((e) => InterfaceModel.fromJson(e)).toList();
  }

  Future<void> editInterface(String realName, InterfaceModel updated) async {
    await _dio.put(
      '/staticfirewall/interfaces/$realName',
      data: updated.toJson(),
    );
  }

  Future<void> deleteInterface(String realName) async {
    await _dio.delete('/staticfirewall/interfaces/$realName');
  }
}
