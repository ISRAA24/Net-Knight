import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';

class SplashService {
  final Dio _dio = BaseService.dio;

  Future<bool> hasUsers() async {
    try {
      final response = await _dio.get('/users');
      final List users = response.data['data'];
      return users.isNotEmpty;
    } catch (_) {
      return true;
    }
  }
}
