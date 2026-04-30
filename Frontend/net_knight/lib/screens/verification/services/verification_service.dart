import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:net_knight/core/network/base_services.dart';

class VerificationService {
  final Dio _dio = BaseService.dio;
  static const _storage = FlutterSecureStorage();

  // ← Signup verification
  Future<void> verifyEmail(String email, String code) async {
    final response = await _dio.post(
      '/auth/verify',
      data: {'email': email, 'code': code},
    );
    final token = response.data['token'];
    if (token != null) {
      await _storage.write(key: 'auth_token', value: token);
    }
  }

  // ← Login verification
  Future<void> verifyLogin(String email, String code) async {
    final response = await _dio.post(
      '/auth/verify-login',
      data: {'email': email, 'code': code},
    );
    final token = response.data['token'];
    if (token != null) {
      await _storage.write(key: 'auth_token', value: token);
    }
  }

  Future<void> resendCode(String email) async {
    await _dio.post(
      '/auth/resend-code',
      data: {'email': email},
    );
  }
}
