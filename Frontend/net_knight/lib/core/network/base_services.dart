import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

class BaseService {
  static Dio? _dioInstance;
  // ignore: unused_field
  static const _storage = FlutterSecureStorage();

  static String get _baseHost => html.window.location.hostname ?? 'localhost';

  static String get previewBaseUrl => 'http://$_baseHost:9090/api';

  static String _resolvedBaseUrl = '';

  // ─── Init ─────────────────────────────────────────────
  static Future<void> init() async {
    String baseUrl = 'http://$_baseHost:3003/api';

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

    _resolvedBaseUrl = baseUrl;

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
            final token = await TokenStorage.getToken();
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

  static String get socketUrl {
    var url = _resolvedBaseUrl;
    if (url.endsWith('/api')) {
      url = url.substring(0, url.length - '/api'.length);
    }
    return url;
  }
}

// ─── Token Storage ────────────────────────────────────────

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = 'auth_token';
  static const _usernameKey = 'username';
  static const _roleKey = 'role';

  static Future<void> saveUserData({
    required String username,
    required String role,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usernameKey, username);
      await prefs.setString(_roleKey, role);
    } else {
      await _storage.write(key: _usernameKey, value: username);
      await _storage.write(key: _roleKey, value: role);
    }
  }

  static Future<String> getUsername() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_usernameKey) ?? 'User';
    } else {
      return await _storage.read(key: _usernameKey) ?? 'User';
    }
  }

  static Future<String> getRole() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_roleKey) ?? '';
    } else {
      return await _storage.read(key: _roleKey) ?? '';
    }
  }

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