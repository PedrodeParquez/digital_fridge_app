import 'api_client.dart';

class ReceiptItem {
  final String name;
  final double quantity;
  final double priceRub;
  final double sumRub;

  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.priceRub,
    required this.sumRub,
  });
}

class ReceiptData {
  final String shopName;
  final String address;
  final DateTime dateTime;
  final double totalRub;
  final List<ReceiptItem> items;

  const ReceiptData({
    required this.shopName,
    required this.address,
    required this.dateTime,
    required this.totalRub,
    required this.items,
  });
}

class ReceiptService {
  static final ReceiptService instance = ReceiptService._();
  ReceiptService._();

  final _dio = ApiClient.instance.dio;

  Future<ReceiptData> fetchByQr(String qrRaw) async {
    final response = await _dio.post('/receipts/parse', data: {'qrraw': qrRaw});
    return _parse(response.data as Map<String, dynamic>);
  }

  ReceiptData _parse(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) {
      final m = e as Map<String, dynamic>;
      return ReceiptItem(
        name: (m['name'] as String? ?? 'Товар').trim(),
        quantity: (m['quantity'] as num?)?.toDouble() ?? 1,
        priceRub: (m['price_rub'] as num?)?.toDouble() ?? 0,
        sumRub: (m['sum_rub'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    DateTime date;
    try {
      date = DateTime.parse(json['date'] as String? ?? '');
    } catch (_) {
      date = DateTime.now();
    }

    return ReceiptData(
      shopName: (json['shop_name'] as String? ?? 'Магазин').trim(),
      address: (json['address'] as String? ?? '').trim(),
      dateTime: date,
      totalRub: (json['total_rub'] as num?)?.toDouble() ?? 0,
      items: items,
    );
  }
}
