import 'package:flutter/material.dart';
import '../../models/fridge_item.dart';
import '../../services/product_service.dart';
import '../../store.dart';

class ProductDetailScreen extends StatelessWidget {
  final FridgeItem item;

  const ProductDetailScreen({super.key, required this.item});

  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _formatQty(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toString();

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить продукт?'),
        content: Text('«${item.productName}» будет удалён из холодильника.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ProductService.instance.deleteFridgeItem(item.id);
        AppStore.instance.removeFridgeItem(item.id);
      } catch (_) {}
      if (context.mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasNutrition =
        item.calories > 0 ||
        item.proteins > 0 ||
        item.fats > 0 ||
        item.carbs > 0;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: cs.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          item.productName,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
            onPressed: () => _delete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.image_outlined,
                size: 64,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _shadow,
              ),
              child: Column(
                children: [
                  _infoRow(
                    cs,
                    Icons.kitchen_outlined,
                    'Количество',
                    '${_formatQty(item.quantity)} ${item.unit}',
                  ),
                  _divider(cs),
                  _infoRow(
                    cs,
                    Icons.calendar_today_outlined,
                    'Добавлен',
                    _formatDate(item.addedAt),
                  ),
                  if (item.expiryDate != null) ...[
                    _divider(cs),
                    _infoRow(
                      cs,
                      item.isExpired
                          ? Icons.warning_amber_rounded
                          : item.isExpiringSoon
                          ? Icons.hourglass_bottom_outlined
                          : Icons.event_available_outlined,
                      'Срок годности',
                      _formatDate(item.expiryDate!),
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
            if (hasNutrition) ...[
              const SizedBox(height: 20),
              Text(
                'Пищевая ценность (на 100 г)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _shadow,
                ),
                child: Row(
                  children: [
                    _nutritionCell(
                      cs,
                      'Ккал',
                      item.calories.toStringAsFixed(0),
                      cs.primary,
                    ),
                    _nutritionDivider(cs),
                    _nutritionCell(
                      cs,
                      'Белки',
                      '${item.proteins.toStringAsFixed(1)} г',
                      Colors.blue,
                    ),
                    _nutritionDivider(cs),
                    _nutritionCell(
                      cs,
                      'Жиры',
                      '${item.fats.toStringAsFixed(1)} г',
                      Colors.orange,
                    ),
                    _nutritionDivider(cs),
                    _nutritionCell(
                      cs,
                      'Углев.',
                      '${item.carbs.toStringAsFixed(1)} г',
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    ColorScheme cs,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 12),
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

  Widget _divider(ColorScheme cs) => Divider(height: 0, color: cs.outline);

  Widget _nutritionCell(
    ColorScheme cs,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _nutritionDivider(ColorScheme cs) =>
      Container(width: 1, height: 36, color: cs.outline);
}
