import 'package:dio/dio.dart';
import '../models/signup_response.dart';

class SignupService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://paddling-levitator-impromptu.ngrok-free.dev/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<SignupResponse> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/signup',
      data: {
        'username': username,
        'email': email,
        'password': password,
      },
    );

    return SignupResponse.fromJson(response.data);
  }
}
