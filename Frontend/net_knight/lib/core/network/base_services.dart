import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class BaseService {
  static Dio? _dioInstance;
  static const _storage = FlutterSecureStorage();
  static const String previewBaseUrl = 'http://100.92.143.50:5000/api';

  // ─── Init ─────────────────────────────────────────────
  static Future<void> init() async {
    String baseUrl = 'http://100.97.136.8:3003/api';

    if (kIsWeb) {
      try {
        final res = await http.get(
          Uri.parse('${Uri.base.origin}/config.json'),
        );
        if (res.statusCode == 200) {
          final config = json.decode(res.body);
          baseUrl = config['apiUrl'] ?? baseUrl;
        }
      } catch (_) {}
    }

    _dioInstance = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    )..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token =
                await TokenStorage.getToken(); // ← غيري لـ TokenStorage
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          },
          onError: (error, handler) {
            handler.next(error);
          },
        ),
      );
  }

  static Dio get dio {
    assert(_dioInstance != null, 'BaseService.init() must be called first');
    return _dioInstance!;
  }
}

// ─── Token Storage ────────────────────────────────────────
// بيشتغل على ويب وموبايل وديسكتوب
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = 'auth_token';

  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, token);
    } else {
      await _storage.write(key: _key, value: token);
    }
  }

  static Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key);
    } else {
      return _storage.read(key: _key);
    }
  }

  static Future<void> deleteToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } else {
      await _storage.delete(key: _key);
    }
  }
}
