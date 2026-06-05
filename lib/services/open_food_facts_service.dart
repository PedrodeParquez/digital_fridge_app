import 'package:dio/dio.dart';

class FoodProduct {
  final String name;
  final String brand;
  final String barcode;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
  final String imageUrl;

  const FoodProduct({
    required this.name,
    required this.brand,
    required this.barcode,
    this.calories = 0,
    this.proteins = 0,
    this.fats = 0,
    this.carbs = 0,
    this.imageUrl = '',
  });

  factory FoodProduct.fromJson(Map<String, dynamic> json) {
    final nutriments = json['nutriments'] as Map<String, dynamic>? ?? {};
    return FoodProduct(
      name:
          (json['product_name_ru'] as String?) ??
          (json['product_name'] as String?) ??
          'Без названия',
      brand: json['brands'] as String? ?? '',
      barcode: json['code'] as String? ?? '',
      calories: (nutriments['energy-kcal_100g'] as num?)?.toDouble() ?? 0,
      proteins: (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0,
      fats: (nutriments['fat_100g'] as num?)?.toDouble() ?? 0,
      carbs: (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_small_url'] as String? ?? '',
    );
  }
}

class OpenFoodFactsService {
  static final OpenFoodFactsService instance = OpenFoodFactsService._();
  OpenFoodFactsService._();

  final _dio = Dio(
    BaseOptions(
      baseUrl: 'https://ru.openfoodfacts.org',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'User-Agent': 'DigitalFridgeApp/1.0 (Flutter)'},
    ),
  );

  Future<List<FoodProduct>> search(String query) async {
    final response = await _dio.get(
      '/cgi/search.pl',
      queryParameters: {
        'search_terms': query,
        'search_simple': 1,
        'action': 'process',
        'json': 1,
        'page_size': 20,
        'lc': 'ru',
        'cc': 'ru',
        'fields':
            'code,product_name,product_name_ru,brands,nutriments,image_small_url',
      },
    );
    final products = response.data['products'] as List<dynamic>? ?? [];
    return products
        .map((e) => FoodProduct.fromJson(e as Map<String, dynamic>))
        .where((p) => p.name != 'Без названия')
        .toList();
  }

  Future<FoodProduct?> getByBarcode(String barcode) async {
    try {
      final response = await _dio.get(
        '/api/v0/product/$barcode.json',
        queryParameters: {
          'fields':
              'code,product_name,product_name_ru,brands,nutriments,image_small_url',
        },
      );
      if (response.data['status'] == 1) {
        return FoodProduct.fromJson(
          response.data['product'] as Map<String, dynamic>,
        );
      }
      return null;
    } on DioException {
      return null;
    }
  }
}
