import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/fridge_item.dart';
import '../../services/open_food_facts_service.dart';
import '../../services/product_service.dart';
import '../../store.dart';

void showProductSheet(
  BuildContext context,
  FridgeItem item, {
  VoidCallback? onDeleted,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ProductSheet(item: item, onDeleted: onDeleted),
  );
}

Future<FoodProduct?> searchNutrition(String productName) async {
  final words = productName.trim().split(RegExp(r'\s+'));
  final queries = [if (words.length >= 2) words.take(2).join(' '), words.first];
  for (final q in queries) {
    if (q.length < 2) continue;
    try {
      final results = await OpenFoodFactsService.instance.search(q);
      final valid = results.where((r) => r.calories > 0).toList();
      if (valid.isNotEmpty) return valid.first;
    } catch (_) {}
  }
  return null;
}

Future<String?> loadCachedImageUrl(String productName) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'nutrition_${productName.toLowerCase().trim()}';
  final raw = prefs.getString(key);
  if (raw == null) return null;
  final m = jsonDecode(raw) as Map<String, dynamic>;
  final url = m['image_url'] as String?;
  return (url != null && url.isNotEmpty) ? url : null;
}

class ProductSheet extends StatefulWidget {
  final FridgeItem item;
  final VoidCallback? onDeleted;

  const ProductSheet({super.key, required this.item, this.onDeleted});

  @override
  State<ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<ProductSheet> {
  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  double? _calories;
  double? _proteins;
  double? _fats;
  double? _carbs;
  bool _loading = false;

  static String _cacheKey(String name) =>
      'nutrition_${name.toLowerCase().trim()}';

  static Future<Map<String, double>?> _loadCache(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(name));
    if (raw == null) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return {
      'calories': (m['calories'] as num).toDouble(),
      'proteins': (m['proteins'] as num).toDouble(),
      'fats': (m['fats'] as num).toDouble(),
      'carbs': (m['carbs'] as num).toDouble(),
    };
  }

  static Future<void> _saveCache(
    String name, {
    required double calories,
    required double proteins,
    required double fats,
    required double carbs,
    String imageUrl = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey(name),
      jsonEncode({
        'calories': calories,
        'proteins': proteins,
        'fats': fats,
        'carbs': carbs,
        'image_url': imageUrl,
      }),
    );
  }

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item.calories > 0 ||
        item.proteins > 0 ||
        item.fats > 0 ||
        item.carbs > 0) {
      _calories = item.calories;
      _proteins = item.proteins;
      _fats = item.fats;
      _carbs = item.carbs;
    } else {
      _initNutrition();
    }
  }

  Future<void> _initNutrition() async {
    final cached = await _loadCache(widget.item.productName);
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _calories = cached['calories'];
        _proteins = cached['proteins'];
        _fats = cached['fats'];
        _carbs = cached['carbs'];
      });
      return;
    }

    await _fetchNutrition();
  }

  Future<void> _fetchNutrition() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final off = await searchNutrition(widget.item.productName);

    if (!mounted) return;
    if (off != null) {
      setState(() {
        _calories = off.calories;
        _proteins = off.proteins;
        _fats = off.fats;
        _carbs = off.carbs;
      });

      await _saveCache(
        widget.item.productName,
        calories: off.calories,
        proteins: off.proteins,
        fats: off.fats,
        carbs: off.carbs,
        imageUrl: off.imageUrl,
      );

      final updated = FridgeItem(
        id: widget.item.id,
        productName: widget.item.productName,
        quantity: widget.item.quantity,
        unit: widget.item.unit,
        addedAt: widget.item.addedAt,
        expiryDate: widget.item.expiryDate,
        calories: off.calories,
        proteins: off.proteins,
        fats: off.fats,
        carbs: off.carbs,
        imageUrl: off.imageUrl,
      );

      final idx = AppStore.instance.fridgeItems.indexWhere(
        (i) => i.id == widget.item.id,
      );
      if (idx != -1) AppStore.instance.fridgeItems[idx] = updated;

      try {
        await ProductService.instance.updateFridgeItem(updated);
      } catch (_) {}
    }

    if (mounted) setState(() => _loading = false);
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _qty(double q) => q % 1 == 0 ? q.toInt().toString() : q.toString();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item = widget.item;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            item.productName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _shadow,
            ),
            child: Column(
              children: [
                _row(
                  cs,
                  Icons.kitchen_outlined,
                  'Количество',
                  '${_qty(item.quantity)} ${item.unit}',
                ),
                Divider(height: 0, color: cs.outline),
                _row(
                  cs,
                  Icons.calendar_today_outlined,
                  'Добавлен',
                  _date(item.addedAt),
                ),
                if (item.expiryDate != null) ...[
                  Divider(height: 0, color: cs.outline),
                  _row(
                    cs,
                    item.isExpired
                        ? Icons.warning_amber_rounded
                        : Icons.event_available_outlined,
                    'Срок годности',
                    _date(item.expiryDate!),
                    valueColor: item.isExpired
                        ? Colors.red
                        : item.isExpiringSoon
                        ? Colors.orange
                        : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _shadow,
            ),
            child: _loading
                ? Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Загружаем КБЖУ...',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : _calories != null
                ? Row(
                    children: [
                      _nutCell(
                        cs,
                        'Ккал',
                        _calories!.toStringAsFixed(0),
                        cs.primary,
                      ),
                      Container(width: 1, height: 32, color: cs.outline),
                      _nutCell(
                        cs,
                        'Белки',
                        '${_proteins!.toStringAsFixed(1)} г',
                        Colors.blue,
                      ),
                      Container(width: 1, height: 32, color: cs.outline),
                      _nutCell(
                        cs,
                        'Жиры',
                        '${_fats!.toStringAsFixed(1)} г',
                        Colors.orange,
                      ),
                      Container(width: 1, height: 32, color: cs.outline),
                      _nutCell(
                        cs,
                        'Углев.',
                        '${_carbs!.toStringAsFixed(1)} г',
                        Colors.purple,
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      'КБЖУ не найдено',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                AppStore.instance.removeFridgeItem(item.id);
                widget.onDeleted?.call();
                Navigator.pop(context);
                try {
                  await ProductService.instance.deleteFridgeItem(item.id);
                } catch (_) {}
              },
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              label: Text(
                'Удалить',
                style: TextStyle(color: Colors.red.shade400),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade200),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    ColorScheme cs,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutCell(ColorScheme cs, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
