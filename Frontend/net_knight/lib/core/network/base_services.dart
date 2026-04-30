import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BaseService {
  static const _storage = FlutterSecureStorage();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://100.97.136.8:3003/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // بيضيف الـ token أوتوماتيك في كل request
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // لو 401 يرجع للـ login
          handler.next(error);
        },
      ),
    );
}
