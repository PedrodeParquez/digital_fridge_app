import 'models/diary.dart';
import 'models/fridge_item.dart';
import 'models/generated_meal_plan.dart';
import 'models/meal_plan.dart';
import 'models/preference_option.dart';
import 'models/purchase.dart';
import 'models/recipe.dart';
import 'models/user_preferences.dart';

class AppStore {
  static final AppStore instance = AppStore._();
  AppStore._();

  final List<FridgeItem> fridgeItems = [];
  final List<Recipe> recipes = [];
  final Set<String> favoriteRecipeIds = {};
  final List<MealPlan> mealPlans = [];
  final List<Purchase> purchases = [];
  UserPreferences? preferences;
  PreferencesOptions? preferencesOptions;
  GeneratedMealPlan? currentMealPlan;
  DailyTargets? dailyTargets;
  DiaryDay? todayDiary;

  List<PreferenceOption> get kitchenEquipmentOptions =>
      preferencesOptions?.kitchenEquipment ?? [];

  void addPurchase(Purchase p) => purchases.add(p);

  void addFridgeItem(FridgeItem item) => fridgeItems.add(item);
  void removeFridgeItem(String id) =>
      fridgeItems.removeWhere((i) => i.id == id);

  void addRecipe(Recipe recipe) => recipes.add(recipe);

  void updateRecipe(Recipe recipe) {
    final idx = recipes.indexWhere((r) => r.id == recipe.id);
    if (idx != -1) recipes[idx] = recipe;
  }

  void removeRecipe(String id) {
    recipes.removeWhere((r) => r.id == id);
    favoriteRecipeIds.remove(id);
  }

  void toggleFavorite(String recipeId) {
    if (favoriteRecipeIds.contains(recipeId)) {
      favoriteRecipeIds.remove(recipeId);
    } else {
      favoriteRecipeIds.add(recipeId);
    }
  }

  void addMealPlan(MealPlan plan) => mealPlans.add(plan);

  List<Recipe> get myRecipes => recipes
      .where((r) => r.isPersonal || favoriteRecipeIds.contains(r.id))
      .toList();

  List<Recipe> get recommendations =>
      recipes.where((r) => !r.isPersonal).toList();
}
