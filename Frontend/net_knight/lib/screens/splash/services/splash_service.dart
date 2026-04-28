import 'package:dio/dio.dart';

class SplashService {
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

  Future<bool> hasUsers() async {
    try {
      final response = await _dio.get('/users');
      final List users = response.data;
      return users.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
