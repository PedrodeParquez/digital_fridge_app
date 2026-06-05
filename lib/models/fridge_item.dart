class FridgeItem {
  final String id;
  final String productName;
  final double quantity;
  final String unit;
  final DateTime addedAt;
  final DateTime? expiryDate;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
  final String imageUrl;

  FridgeItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unit,
    DateTime? addedAt,
    this.expiryDate,
    this.calories = 0,
    this.proteins = 0,
    this.fats = 0,
    this.carbs = 0,
    this.imageUrl = '',
  }) : addedAt = addedAt ?? DateTime.now();

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    return expiryDate!.difference(DateTime.now()).inDays <= 3;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  factory FridgeItem.fromJson(Map<String, dynamic> json) {
    return FridgeItem(
      id: json['id'].toString(),
      productName: json['product_name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      addedAt: json['added_at'] != null
          ? DateTime.parse(json['added_at'] as String)
          : DateTime.now(),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      proteins: (json['proteins'] as num?)?.toDouble() ?? 0,
      fats: (json['fats'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'product_name': productName,
    'quantity': quantity,
    'unit': unit,
    'expiry_date': expiryDate?.toIso8601String(),
    'calories': calories,
    'proteins': proteins,
    'fats': fats,
    'carbs': carbs,
    'image_url': imageUrl,
  };
}
