class GeneratedMealRecipe {
  final int id;
  final String name;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
  final int cookTimeMinutes;

  const GeneratedMealRecipe({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
    required this.cookTimeMinutes,
  });

  factory GeneratedMealRecipe.fromJson(Map<String, dynamic> j) =>
      GeneratedMealRecipe(
        id: j['id'] as int,
        name: j['name'] as String,
        calories: (j['calories'] as num).toDouble(),
        proteins: (j['proteins'] as num).toDouble(),
        fats: (j['fats'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        cookTimeMinutes: j['cook_time_minutes'] as int,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'calories': calories,
    'proteins': proteins,
    'fats': fats,
    'carbs': carbs,
    'cook_time_minutes': cookTimeMinutes,
  };

  String get cookTimeLabel {
    if (cookTimeMinutes < 60) return '$cookTimeMinutes мин';
    final h = cookTimeMinutes ~/ 60;
    final m = cookTimeMinutes % 60;
    return m == 0 ? '$h ч' : '$h ч $m мин';
  }
}

class GeneratedMealDay {
  final DateTime date;
  final GeneratedMealRecipe? breakfast;
  final GeneratedMealRecipe? lunch;
  final GeneratedMealRecipe? snack;
  final GeneratedMealRecipe? dinner;

  const GeneratedMealDay({
    required this.date,
    this.breakfast,
    this.lunch,
    this.snack,
    this.dinner,
  });

  factory GeneratedMealDay.fromJson(Map<String, dynamic> j) => GeneratedMealDay(
    date: DateTime.parse(j['date'] as String),
    breakfast: j['breakfast'] != null
        ? GeneratedMealRecipe.fromJson(j['breakfast'] as Map<String, dynamic>)
        : null,
    lunch: j['lunch'] != null
        ? GeneratedMealRecipe.fromJson(j['lunch'] as Map<String, dynamic>)
        : null,
    snack: j['snack'] != null
        ? GeneratedMealRecipe.fromJson(j['snack'] as Map<String, dynamic>)
        : null,
    dinner: j['dinner'] != null
        ? GeneratedMealRecipe.fromJson(j['dinner'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String().substring(0, 10),
    'breakfast': breakfast?.toJson(),
    'lunch': lunch?.toJson(),
    'snack': snack?.toJson(),
    'dinner': dinner?.toJson(),
  };

  double get totalCalories =>
      (breakfast?.calories ?? 0) +
      (lunch?.calories ?? 0) +
      (snack?.calories ?? 0) +
      (dinner?.calories ?? 0);
}

class GeneratedMealPlan {
  final int id;
  final String name;
  final DateTime startDate;
  final List<GeneratedMealDay> days;

  const GeneratedMealPlan({
    required this.id,
    required this.name,
    required this.startDate,
    required this.days,
  });

  factory GeneratedMealPlan.fromJson(Map<String, dynamic> j) =>
      GeneratedMealPlan(
        id: j['id'] as int,
        name: j['name'] as String,
        startDate: DateTime.parse(j['start_date'] as String),
        days: (j['days'] as List<dynamic>)
            .map((d) => GeneratedMealDay.fromJson(d as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'start_date': startDate.toIso8601String().substring(0, 10),
    'days': days.map((d) => d.toJson()).toList(),
  };

  DateTime get endDate => startDate.add(Duration(days: days.length - 1));

  double get avgDailyCalories {
    if (days.isEmpty) return 0;
    return days.map((d) => d.totalCalories).reduce((a, b) => a + b) /
        days.length;
  }
}

class ShoppingItem {
  final String productName;
  final double quantityNeeded;
  final double quantityInFridge;
  final double quantityToBuy;
  final String unit;

  const ShoppingItem({
    required this.productName,
    required this.quantityNeeded,
    required this.quantityInFridge,
    required this.quantityToBuy,
    required this.unit,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> j) => ShoppingItem(
    productName: j['product_name'] as String,
    quantityNeeded: (j['quantity_needed'] as num).toDouble(),
    quantityInFridge: (j['quantity_in_fridge'] as num).toDouble(),
    quantityToBuy: (j['quantity_to_buy'] as num).toDouble(),
    unit: j['unit'] as String,
  );
}
