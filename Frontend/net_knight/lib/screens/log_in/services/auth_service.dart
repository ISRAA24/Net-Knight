import 'package:dio/dio.dart';
import '../../../core/network/base_services.dart';
import '../models/login_response.dart';

class AuthService {
  final Dio _dio = BaseService.dio;

  Future<LoginResponse> login(String username, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    return LoginResponse.fromJson(response.data);
  }
}
