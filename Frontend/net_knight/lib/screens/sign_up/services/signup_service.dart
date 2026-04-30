import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/signup_response.dart';

class SignupService {
  final Dio _dio = BaseService.dio;

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
