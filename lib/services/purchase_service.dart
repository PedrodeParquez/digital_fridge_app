import '../models/purchase.dart';
import 'api_client.dart';

class PurchaseService {
  static final PurchaseService instance = PurchaseService._();
  PurchaseService._();

  final _dio = ApiClient.instance.dio;

  Future<List<Purchase>> getPurchases() async {
    final response = await _dio.get('/purchases');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => Purchase.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Purchase> createPurchase(Purchase purchase) async {
    final response = await _dio.post('/purchases', data: purchase.toJson());
    return Purchase.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePurchase(String id) async {
    await _dio.delete('/purchases/$id');
  }
}
