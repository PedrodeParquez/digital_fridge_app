import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const baseUrl = 'http://10.0.2.2:8080';
  static const _baseUrl = '$baseUrl/api/v1';
  static const _tokenKey = 'access_token';

  static final ApiClient instance = ApiClient._();
  ApiClient._();

  late final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.addAll([
          _AuthInterceptor(),
          LogInterceptor(requestBody: true, responseBody: true),
        ]);

  Dio get dio => _dio;

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> get isLoggedIn async => (await getToken()) != null;
}

class _AuthInterceptor extends Interceptor {
  static const _tokenKey = 'access_token';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      SharedPreferences.getInstance().then((p) => p.remove(_tokenKey));
    }
    handler.next(err);
  }
}
