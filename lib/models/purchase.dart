enum PurchaseType { store, delivery }

class PurchaseItem {
  final String name;
  final double quantity;
  final String unit;
  final String price;

  const PurchaseItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) => PurchaseItem(
    name: json['name'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    unit: json['unit'] as String,
    price: json['price'] as String,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'price': price,
  };
}

class Purchase {
  final String id;
  final String name;
  final String totalPrice;
  final String date;
  final PurchaseType type;
  final List<PurchaseItem> items;

  int get itemsCount => items.length;

  const Purchase({
    required this.id,
    required this.name,
    required this.totalPrice,
    required this.date,
    required this.type,
    required this.items,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
    id: json['id'].toString(),
    name: json['name'] as String,
    totalPrice: json['total_price'] as String,
    date: json['date'] as String,
    type: json['type'] == 'delivery'
        ? PurchaseType.delivery
        : PurchaseType.store,
    items:
        (json['items'] as List<dynamic>?)
            ?.map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'total_price': totalPrice,
    'date': date,
    'type': type == PurchaseType.delivery ? 'delivery' : 'store',
    'items': items.map((e) => e.toJson()).toList(),
  };
}
