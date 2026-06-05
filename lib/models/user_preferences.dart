class UserPreferences {
  final List<String> intolerances;
  final List<String> favoriteProducts;
  final List<String> favoriteCuisines;
  final List<String> kitchenEquipment;
  final int? calorieLimit;
  final String? goal;

  const UserPreferences({
    this.intolerances = const [],
    this.favoriteProducts = const [],
    this.favoriteCuisines = const [],
    this.kitchenEquipment = const [],
    this.calorieLimit,
    this.goal,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        intolerances: _toStringList(json['intolerances']),
        favoriteProducts: _toStringList(json['favorite_products']),
        favoriteCuisines: _toStringList(json['favorite_cuisines']),
        kitchenEquipment: _toStringList(json['kitchen_equipment']),
        calorieLimit: json['calorie_limit'] as int?,
        goal: json['goal'] as String?,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'intolerances': intolerances,
      'favorite_products': favoriteProducts,
      'favorite_cuisines': favoriteCuisines,
      'kitchen_equipment': kitchenEquipment,
      'goal': goal,
    };
    if (calorieLimit != null) map['calorie_limit'] = calorieLimit;
    return map;
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}
