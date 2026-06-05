import '../models/diary.dart';
import 'api_client.dart';

class DiaryService {
  static final DiaryService instance = DiaryService._();
  DiaryService._();

  final _dio = ApiClient.instance.dio;

  Future<DailyTargets> getDailyTargets() async {
    final response = await _dio.get('/profile/daily-targets');
    return DailyTargets.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DiaryDay> getTodayDiary() async {
    final response = await _dio.get('/diary/today');
    return DiaryDay.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DiaryEntry> addEntry({
    required String date,
    required String mealType,
    String? name,
    int? recipeId,
    required double calories,
    required double proteins,
    required double fats,
    required double carbs,
  }) async {
    final data = <String, dynamic>{
      'date': date,
      'meal_type': mealType,
      'calories': calories,
      'proteins': proteins,
      'fats': fats,
      'carbs': carbs,
    };
    if (name != null) data['name'] = name;
    if (recipeId != null) data['recipe_id'] = recipeId;

    final response = await _dio.post('/diary', data: data);
    return DiaryEntry.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteEntry(int id) async {
    await _dio.delete('/diary/$id');
  }
}
