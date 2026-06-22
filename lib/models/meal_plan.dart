class DailyRation {
  final DateTime date;

  final int? breakfastRecipeId;
  final int? lunchRecipeId;
  final int? snackRecipeId;
  final int? dinnerRecipeId;
  final String? breakfast;
  final String? lunch;
  final String? snack;
  final String? dinner;

  DailyRation({
    required this.date,
    this.breakfastRecipeId,
    this.lunchRecipeId,
    this.snackRecipeId,
    this.dinnerRecipeId,
    this.breakfast,
    this.lunch,
    this.snack,
    this.dinner,
  });

  bool get isEmpty =>
      breakfastRecipeId == null &&
      lunchRecipeId == null &&
      snackRecipeId == null &&
      dinnerRecipeId == null;

  factory DailyRation.fromJson(Map<String, dynamic> json) => DailyRation(
    date: DateTime.parse(json['date'] as String),
    breakfastRecipeId: json['breakfast_recipe_id'] as int?,
    lunchRecipeId: json['lunch_recipe_id'] as int?,
    snackRecipeId: json['snack_recipe_id'] as int?,
    dinnerRecipeId: json['dinner_recipe_id'] as int?,
    breakfast: json['breakfast'] as String?,
    lunch: json['lunch'] as String?,
    snack: json['snack'] as String?,
    dinner: json['dinner'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'breakfast_recipe_id': breakfastRecipeId,
    'lunch_recipe_id': lunchRecipeId,
    'snack_recipe_id': snackRecipeId,
    'dinner_recipe_id': dinnerRecipeId,
  };

  DailyRation copyWith({
    DateTime? date,
    Object? breakfastRecipeId = _absent,
    Object? lunchRecipeId = _absent,
    Object? snackRecipeId = _absent,
    Object? dinnerRecipeId = _absent,
    Object? breakfast = _absent,
    Object? lunch = _absent,
    Object? snack = _absent,
    Object? dinner = _absent,
  }) => DailyRation(
    date: date ?? this.date,
    breakfastRecipeId: breakfastRecipeId == _absent
        ? this.breakfastRecipeId
        : breakfastRecipeId as int?,
    lunchRecipeId: lunchRecipeId == _absent
        ? this.lunchRecipeId
        : lunchRecipeId as int?,
    snackRecipeId: snackRecipeId == _absent
        ? this.snackRecipeId
        : snackRecipeId as int?,
    dinnerRecipeId: dinnerRecipeId == _absent
        ? this.dinnerRecipeId
        : dinnerRecipeId as int?,
    breakfast: breakfast == _absent ? this.breakfast : breakfast as String?,
    lunch: lunch == _absent ? this.lunch : lunch as String?,
    snack: snack == _absent ? this.snack : snack as String?,
    dinner: dinner == _absent ? this.dinner : dinner as String?,
  );
}

const _absent = Object();

class MealPlan {
  final String id;
  final String name;
  final DateTime startDate;
  final List<DailyRation> days;

  MealPlan({
    required this.id,
    required this.name,
    required this.startDate,
    required this.days,
  });

  DateTime get endDate => days.last.date;
  int get daysCount => days.length;

  factory MealPlan.fromJson(Map<String, dynamic> json) => MealPlan(
    id: json['id'].toString(),
    name: json['name'] as String,
    startDate: DateTime.parse(json['start_date'] as String),
    days: (json['days'] as List<dynamic>)
        .map((e) => DailyRation.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'start_date': startDate.toIso8601String(),
    'days': days.map((e) => e.toJson()).toList(),
  };
}
