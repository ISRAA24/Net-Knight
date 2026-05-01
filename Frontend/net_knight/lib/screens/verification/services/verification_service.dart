import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';

class VerificationService {
  final Dio _dio = BaseService.dio;

  // ← Signup verification
  Future<bool> verifyEmail(String email, String code) async {
    final response = await _dio.post(
      '/auth/verify',
      data: {'email': email, 'code': code},
    );
    final token = response.data['token'];
    if (token != null) {
      await TokenStorage.saveToken(token.toString()); // ← TokenStorage
      return true;
    }
    return false;
  }

  // ← Login verification
  Future<bool> verifyLogin(String email, String code) async {
    final response = await _dio.post(
      '/auth/verify-login',
      data: {'email': email, 'code': code},
    );
    final token = response.data['token'];
    if (token != null) {
      await TokenStorage.saveToken(token.toString()); // ← TokenStorage
      return true;
    }
    return false;
  }

  Future<void> resendCode(String email) async {
    await _dio.post(
      '/auth/resend-code',
      data: {'email': email},
    );
  }
}
