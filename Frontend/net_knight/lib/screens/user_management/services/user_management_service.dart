import 'package:dio/dio.dart';
import '../models/user_model.dart';

class UserManagementService {
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

  Future<List<UserModel>> getUsers() async {
    final response = await _dio.get('/users');
    final List data = response.data;
    return data.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> addUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    await _dio.post(
      '/users',
      data: {
        'username': name,
        'email': email,
        'password': password,
        'role': role,
      },
    );
  }

  Future<void> editUser(String id, UserModel user) async {
    await _dio.put(
      '/users/$id',
      data: user.toJson(),
    );
  }

  Future<void> deleteUser(String id) async {
    await _dio.delete('/users/$id');
  }
}
