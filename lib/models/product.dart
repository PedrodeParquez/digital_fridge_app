class Product {
  final String id;
  final String name;
  final String description;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;

  const Product({
    required this.id,
    required this.name,
    this.description = '',
    this.calories = 0,
    this.proteins = 0,
    this.fats = 0,
    this.carbs = 0,
  });
}
