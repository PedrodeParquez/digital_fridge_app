class DailyRation {
  final DateTime date;
  String? breakfast;
  String? lunch;
  String? snack;
  String? dinner;

  DailyRation({
    required this.date,
    this.breakfast,
    this.lunch,
    this.snack,
    this.dinner,
  });

  bool get isEmpty =>
      breakfast == null && lunch == null && snack == null && dinner == null;

  factory DailyRation.fromJson(Map<String, dynamic> json) => DailyRation(
    date: DateTime.parse(json['date'] as String),
    breakfast: json['breakfast'] as String?,
    lunch: json['lunch'] as String?,
    snack: json['snack'] as String?,
    dinner: json['dinner'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'breakfast': breakfast,
    'lunch': lunch,
    'snack': snack,
    'dinner': dinner,
  };
}

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
