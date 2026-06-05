import '../models/fridge_item.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';
import '../store.dart';
import 'meal_plan_service.dart';

class ShoppingListService {
  static final ShoppingListService instance = ShoppingListService._();
  ShoppingListService._();

  List<ShoppingListItem> generateFromPlan(MealPlan plan) {
    final store = AppStore.instance;
    final needed = <String, _Needed>{};

    for (final day in plan.days) {
      for (final mealName in [
        day.breakfast,
        day.lunch,
        day.snack,
        day.dinner,
      ]) {
        if (mealName == null) continue;
        final recipe = _findRecipe(store.recipes, mealName);
        if (recipe == null) continue;

        for (final ing in recipe.ingredients) {
          final key = '${ing.productName}__${ing.unit}';
          needed.update(
            key,
            (v) => _Needed(
              productName: ing.productName,
              unit: ing.unit,
              quantity: v.quantity + ing.quantity,
            ),
            ifAbsent: () => _Needed(
              productName: ing.productName,
              unit: ing.unit,
              quantity: ing.quantity,
            ),
          );
        }
      }
    }

    final result = <ShoppingListItem>[];
    for (final n in needed.values) {
      final inFridge = _fridgeQuantity(
        store.fridgeItems,
        n.productName,
        n.unit,
      );
      final missing = (n.quantity - inFridge).clamp(0, double.infinity);
      result.add(
        ShoppingListItem(
          productName: n.productName,
          requiredQuantity: n.quantity,
          availableQuantity: inFridge,
          missingQuantity: missing.toDouble(),
          unit: n.unit,
        ),
      );
    }

    return result.where((e) => e.missingQuantity > 0).toList();
  }

  Recipe? _findRecipe(List<Recipe> recipes, String name) {
    try {
      return recipes.firstWhere(
        (r) => r.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  double _fridgeQuantity(
    List<FridgeItem> items,
    String productName,
    String unit,
  ) {
    double total = 0;
    for (final item in items) {
      if (item.productName.toLowerCase() == productName.toLowerCase() &&
          item.unit == unit) {
        total += item.quantity;
      }
    }
    return total;
  }
}

class _Needed {
  final String productName;
  final String unit;
  final double quantity;
  const _Needed({
    required this.productName,
    required this.unit,
    required this.quantity,
  });
}
