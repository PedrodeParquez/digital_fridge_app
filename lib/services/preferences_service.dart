import '../models/preference_option.dart';
import '../models/user_preferences.dart';
import 'api_client.dart';

class PreferencesService {
  static final PreferencesService instance = PreferencesService._();
  PreferencesService._();

  final _dio = ApiClient.instance.dio;

  Future<UserPreferences> getPreferences() async {
    final response = await _dio.get('/profile/preferences');
    return UserPreferences.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> savePreferences(UserPreferences prefs) async {
    await _dio.put('/profile/preferences', data: prefs.toJson());
  }

  Future<PreferencesOptions> getOptions() async {
    final response = await _dio.get('/preferences/options');
    return PreferencesOptions.fromJson(response.data as Map<String, dynamic>);
  }
}
