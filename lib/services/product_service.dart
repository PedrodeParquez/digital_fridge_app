import '../models/fridge_item.dart';
import 'api_client.dart';

class ProductService {
  static final ProductService instance = ProductService._();
  ProductService._();

  final _dio = ApiClient.instance.dio;

  Future<List<FridgeItem>> getFridgeItems() async {
    final response = await _dio.get('/fridge');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => FridgeItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FridgeItem> addFridgeItem(FridgeItem item) async {
    final response = await _dio.post('/fridge', data: item.toJson());
    return FridgeItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FridgeItem> updateFridgeItem(FridgeItem item) async {
    final response = await _dio.put('/fridge/${item.id}', data: item.toJson());
    return FridgeItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteFridgeItem(String id) async {
    await _dio.delete('/fridge/$id');
  }
}
