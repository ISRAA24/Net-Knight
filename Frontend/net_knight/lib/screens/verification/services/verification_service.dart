import 'package:dio/dio.dart';

class VerificationService {
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

  Future<void> verifyEmail(String email, String code) async {
    await _dio.post(
      '/auth/verify',
      data: {'email': email, 'code': code},
    );
  }

  Future<void> resendCode(String email) async {
    await _dio.post(
      '/auth/resend-code',
      data: {'email': email},
    );
  }
}
