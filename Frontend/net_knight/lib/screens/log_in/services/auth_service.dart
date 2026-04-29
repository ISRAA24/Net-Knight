import 'package:dio/dio.dart';
import '../models/login_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://paddling-levitator-impromptu.ngrok-free.dev/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final _storage = const FlutterSecureStorage();

  Future<LoginResponse> login(String username, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );

    final loginResponse = LoginResponse.fromJson(response.data);
    await _storage.write(key: 'auth_token', value: loginResponse.token);
    return loginResponse;
  }
}
