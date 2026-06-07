import 'package:dio/dio.dart';
import 'api_client.dart';

class FoodProduct {
  final String name;
  final String brand;
  final String barcode;
  final String? quantity;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
  final String imageUrl;
  final List<String> categoriesTags;
  final List<String> countriesTags;

  const FoodProduct({
    required this.name,
    required this.brand,
    required this.barcode,
    this.quantity,
    this.calories = 0,
    this.proteins = 0,
    this.fats = 0,
    this.carbs = 0,
    this.imageUrl = '',
    this.categoriesTags = const [],
    this.countriesTags = const [],
  });

  bool get isSoldInRussia => countriesTags.contains('en:russia');

  factory FoodProduct.fromJson(Map<String, dynamic> json) {
    return FoodProduct(
      name: json['name'] as String? ?? 'Без названия',
      brand: json['brand'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      quantity: json['quantity'] as String?,
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      proteins: (json['proteins'] as num?)?.toDouble() ?? 0,
      fats: (json['fats'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
      categoriesTags:
          (json['categories_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      countriesTags:
          (json['countries_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class OpenFoodFactsService {
  static final OpenFoodFactsService instance = OpenFoodFactsService._();
  OpenFoodFactsService._();

  final _dio = ApiClient.instance.dio;

  Future<List<FoodProduct>> search(String query) async {
    final response = await _dio.get(
      '/products/search',
      queryParameters: {'q': query},
    );
    final products = response.data as List<dynamic>? ?? [];
    return products
        .map((e) => FoodProduct.fromJson(e as Map<String, dynamic>))
        .where((p) => p.name != 'Без названия')
        .toList();
  }

  Future<FoodProduct?> getByBarcode(String barcode) async {
    try {
      final response = await _dio.get('/products/barcode/$barcode');
      return FoodProduct.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }
}
