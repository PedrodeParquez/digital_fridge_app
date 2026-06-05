import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthResult {
  final String token;
  final String userId;

  const AuthResult({required this.token, required this.userId});
}

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final _client = ApiClient.instance;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final token = response.data['token'] as String;
    final userId = response.data['user_id'].toString();
    await _client.saveToken(token);
    return AuthResult(token: token, userId: userId);
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.dio.post(
      '/auth/register',
      data: {'email': email, 'password': password, 'name': name},
    );
    final token = response.data['token'] as String;
    final userId = response.data['user_id'].toString();
    await _client.saveToken(token);
    return AuthResult(token: token, userId: userId);
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout');
    } on DioException {
      // игнорируем ошибку сети — токен всё равно удаляем
    } finally {
      await _client.clearToken();
    }
  }

  Future<bool> get isLoggedIn => _client.isLoggedIn;
}
