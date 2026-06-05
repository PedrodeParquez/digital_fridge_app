import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/generated_meal_plan.dart';
import '../models/meal_plan.dart';
import '../store.dart';
import 'api_client.dart';

class MealPlanService {
  static final MealPlanService instance = MealPlanService._();
  MealPlanService._();

  final _dio = ApiClient.instance.dio;

  Future<List<MealPlan>> getMealPlans() async {
    final response = await _dio.get('/meal-plans');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => MealPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MealPlan> getMealPlan(String id) async {
    final response = await _dio.get('/meal-plans/$id');
    return MealPlan.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MealPlan> createMealPlan(MealPlan plan) async {
    final response = await _dio.post('/meal-plans', data: plan.toJson());
    return MealPlan.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MealPlan> updateMealPlan(MealPlan plan) async {
    final response = await _dio.put(
      '/meal-plans/${plan.id}',
      data: plan.toJson(),
    );
    return MealPlan.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteMealPlan(String id) async {
    await _dio.delete('/meal-plans/$id');
  }

  static const _planKey = 'current_meal_plan_v1';

  Future<GeneratedMealPlan> generatePlan(int days) async {
    final response = await _dio.post(
      '/meal-plans/generate',
      data: {'days': days},
    );
    final plan = GeneratedMealPlan.fromJson(response.data as Map<String, dynamic>);
    await savePlanLocally(plan);
    return plan;
  }

  Future<void> savePlanLocally(GeneratedMealPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, jsonEncode(plan.toJson()));
  }

  Future<void> clearPlanLocally() async {
    AppStore.instance.currentMealPlan = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_planKey);
  }

  Future<GeneratedMealPlan?> loadPlanLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_planKey);
      if (raw == null) return null;
      return GeneratedMealPlan.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<ShoppingItem>> getShoppingList(int planId) async {
    final response = await _dio.get('/meal-plans/$planId/shopping-list');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ShoppingListItem>> generateShoppingList(String planId) async {
    final response = await _dio.post(
      '/meal-plans/$planId/generate-shopping-list',
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ShoppingListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class ShoppingListItem {
  final String productName;
  final double requiredQuantity;
  final double availableQuantity;
  final double missingQuantity;
  final String unit;

  const ShoppingListItem({
    required this.productName,
    required this.requiredQuantity,
    required this.availableQuantity,
    required this.missingQuantity,
    required this.unit,
  });

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) =>
      ShoppingListItem(
        productName: json['product_name'] as String,
        requiredQuantity: (json['required_quantity'] as num).toDouble(),
        availableQuantity: (json['available_quantity'] as num).toDouble(),
        missingQuantity: (json['missing_quantity'] as num).toDouble(),
        unit: json['unit'] as String,
      );

  Map<String, dynamic> toJson() => {
    'product_name': productName,
    'required_quantity': requiredQuantity,
    'available_quantity': availableQuantity,
    'missing_quantity': missingQuantity,
    'unit': unit,
  };
}
