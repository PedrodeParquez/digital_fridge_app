import '../models/user_profile.dart';
import 'api_client.dart';

class UserService {
  static final UserService instance = UserService._();
  UserService._();

  final _dio = ApiClient.instance.dio;

  UserProfile? _cached;
  UserProfile? get cached => _cached;
  void clearCache() => _cached = null;

  Future<UserProfile> getProfile() async {
    final response = await _dio.get('/profile');
    _cached = UserProfile.fromJson(response.data as Map<String, dynamic>);
    return _cached!;
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    final response = await _dio.put('/profile', data: profile.toJson());
    _cached = UserProfile.fromJson(response.data as Map<String, dynamic>);
    return _cached!;
  }

  Future<void> updateProfileRaw(Map<String, dynamic> body) async {
    final response = await _dio.put('/profile', data: body);
    _cached = UserProfile.fromJson(response.data as Map<String, dynamic>);
  }
}
