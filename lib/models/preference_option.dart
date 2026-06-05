class PreferenceOption {
  final String key;
  final String label;
  final String? imageUrl;

  const PreferenceOption({
    required this.key,
    required this.label,
    this.imageUrl,
  });

  factory PreferenceOption.fromJson(Map<String, dynamic> json) =>
      PreferenceOption(
        key: json['key'] as String,
        label: json['label'] as String,
        imageUrl: json['image_url'] as String?,
      );
}

class PreferencesOptions {
  final List<PreferenceOption> favoriteProducts;
  final List<PreferenceOption> intolerances;
  final List<PreferenceOption> kitchenEquipment;

  const PreferencesOptions({
    this.favoriteProducts = const [],
    this.intolerances = const [],
    this.kitchenEquipment = const [],
  });

  factory PreferencesOptions.fromJson(Map<String, dynamic> json) {
    List<PreferenceOption> parse(dynamic list) => (list as List<dynamic>? ?? [])
        .map((e) => PreferenceOption.fromJson(e as Map<String, dynamic>))
        .toList();

    return PreferencesOptions(
      favoriteProducts: parse(json['favorite_products']),
      intolerances: parse(json['intolerances']),
      kitchenEquipment: parse(json['kitchen_equipment']),
    );
  }
}
