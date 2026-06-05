class RecipeImage {
  final int id;
  final int recipeId;
  final String url;
  final int order;

  const RecipeImage({
    required this.id,
    required this.recipeId,
    required this.url,
    required this.order,
  });

  factory RecipeImage.fromJson(Map<String, dynamic> json) => RecipeImage(
    id: json['id'] as int,
    recipeId: json['recipe_id'] as int,
    url: json['url'] as String,
    order: json['order'] as int,
  );
}

class RecipeIngredient {
  final String productName;
  final double quantity;
  final String unit;

  const RecipeIngredient({
    required this.productName,
    required this.quantity,
    required this.unit,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        productName: json['product_name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
      );

  Map<String, dynamic> toJson() => {
    'product_name': productName,
    'quantity': quantity,
    'unit': unit,
  };
}

class RecipeStep {
  final int order;
  final String description;

  const RecipeStep({required this.order, required this.description});

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
    order: json['order'] as int,
    description: json['description'] as String,
  );

  Map<String, dynamic> toJson() => {'order': order, 'description': description};
}

class Recipe {
  final String id;
  final String name;
  final String description;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
  final int servings;
  final int cookTimeMinutes;
  final bool isPersonal;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final List<RecipeImage> images;
  final List<String> requiredEquipment;

  Recipe({
    required this.id,
    required this.name,
    this.description = '',
    this.calories = 0,
    this.proteins = 0,
    this.fats = 0,
    this.carbs = 0,
    this.servings = 1,
    this.cookTimeMinutes = 30,
    this.isPersonal = false,
    this.ingredients = const [],
    this.steps = const [],
    this.images = const [],
    this.requiredEquipment = const [],
  });

  String? get mainImageUrl {
    if (images.isEmpty) return null;
    final sorted = [...images]..sort((a, b) => a.order.compareTo(b.order));
    return sorted.first.url;
  }

  String get cookTimeLabel {
    if (cookTimeMinutes < 60) return '$cookTimeMinutes мин';
    final h = cookTimeMinutes ~/ 60;
    final m = cookTimeMinutes % 60;
    return m == 0 ? '$h ч' : '$h ч $m мин';
  }

  String get caloriesLabel => '${calories.toStringAsFixed(0)} ккал';

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'].toString(),
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    calories: (json['calories'] as num?)?.toDouble() ?? 0,
    proteins: (json['proteins'] as num?)?.toDouble() ?? 0,
    fats: (json['fats'] as num?)?.toDouble() ?? 0,
    carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
    servings: json['servings'] as int? ?? 1,
    cookTimeMinutes: json['cook_time_minutes'] as int? ?? 30,
    isPersonal: json['is_personal'] as bool? ?? false,
    ingredients:
        (json['ingredients'] as List<dynamic>?)
            ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    steps:
        (json['steps'] as List<dynamic>?)
            ?.map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    images:
        (json['images'] as List<dynamic>?)
            ?.map((e) => RecipeImage.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    requiredEquipment:
        (json['required_equipment'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'calories': calories,
    'proteins': proteins,
    'fats': fats,
    'carbs': carbs,
    'servings': servings,
    'cook_time_minutes': cookTimeMinutes,
    'is_personal': isPersonal,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'steps': steps.map((e) => e.toJson()).toList(),
    'required_equipment': requiredEquipment,
  };
}
