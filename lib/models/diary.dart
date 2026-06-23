class DailyTargets {
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;

  const DailyTargets({
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  factory DailyTargets.fromJson(Map<String, dynamic> j) => DailyTargets(
    calories: (j['calories'] as num).toDouble(),
    proteins: (j['proteins'] as num).toDouble(),
    fats: (j['fats'] as num).toDouble(),
    carbs: (j['carbs'] as num).toDouble(),
  );

  static const defaultTargets = DailyTargets(
    calories: 2000,
    proteins: 100,
    fats: 67,
    carbs: 250,
  );
}

class DiaryEntry {
  final int id;
  final String date;
  final String mealType;
  final String name;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
  final int? recipeId;

  const DiaryEntry({
    required this.id,
    required this.date,
    required this.mealType,
    required this.name,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
    this.recipeId,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> j) => DiaryEntry(
    id: (j['id'] as num).toInt(),
    date: j['date'] as String? ?? '',
    mealType: j['meal_type'] as String? ?? '',
    name: j['name'] as String? ?? j['recipe_name'] as String? ?? '',
    calories: (j['calories'] as num?)?.toDouble() ?? 0,
    proteins: (j['proteins'] as num?)?.toDouble() ?? 0,
    fats: (j['fats'] as num?)?.toDouble() ?? 0,
    carbs: (j['carbs'] as num?)?.toDouble() ?? 0,
    recipeId: (j['recipe_id'] as num?)?.toInt(),
  );
}

class DiaryTotals {
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;

  const DiaryTotals({
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  factory DiaryTotals.fromJson(Map<String, dynamic> j) => DiaryTotals(
    calories: (j['calories'] as num).toDouble(),
    proteins: (j['proteins'] as num).toDouble(),
    fats: (j['fats'] as num).toDouble(),
    carbs: (j['carbs'] as num).toDouble(),
  );

  static const empty = DiaryTotals(calories: 0, proteins: 0, fats: 0, carbs: 0);
}

class DiaryDay {
  final List<DiaryEntry> entries;
  final DiaryTotals totals;

  const DiaryDay({required this.entries, required this.totals});

  factory DiaryDay.fromJson(Map<String, dynamic> j) => DiaryDay(
    entries: (j['entries'] as List<dynamic>)
        .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    totals: DiaryTotals.fromJson(j['totals'] as Map<String, dynamic>),
  );

  List<DiaryEntry> forMealType(String mealType) =>
      entries.where((e) => e.mealType == mealType).toList();
}
