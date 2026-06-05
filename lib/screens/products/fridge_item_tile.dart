import 'package:flutter/material.dart';
import '../../models/fridge_item.dart';
import 'product_sheet.dart';

class FridgeItemTile extends StatefulWidget {
  final FridgeItem item;
  final List<BoxShadow> shadow;
  final VoidCallback? onDeleted;
  final VoidCallback? onDismissed;

  const FridgeItemTile({
    super.key,
    required this.item,
    required this.shadow,
    this.onDeleted,
    this.onDismissed,
  });

  @override
  State<FridgeItemTile> createState() => _FridgeItemTileState();
}

class _FridgeItemTileState extends State<FridgeItemTile> {
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.item.imageUrl.isNotEmpty) {
      _imageUrl = widget.item.imageUrl;
    } else {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final url = await loadCachedImageUrl(widget.item.productName);
    if (mounted && url != null) setState(() => _imageUrl = url);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _formatQty(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toString();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item = widget.item;

    return Dismissible(
      key: Key('tile_${item.id}_${item.productName}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => widget.onDismissed?.call(),
      child: GestureDetector(
        onTap: () =>
            showProductSheet(context, item, onDeleted: widget.onDeleted),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.shadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: _imageUrl != null
                        ? Image.network(
                            _imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => _placeholder(cs),
                            loadingBuilder: (_, child, progress) =>
                                progress == null ? child : _placeholder(cs),
                          )
                        : _placeholder(cs),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatQty(item.quantity)} ${item.unit}',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (item.expiryDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.isExpired
                              ? 'Истёк срок годности'
                              : item.isExpiringSoon
                              ? 'Истекает скоро'
                              : 'До ${_formatDate(item.expiryDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: item.isExpired
                                ? Colors.red
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
    color: cs.outline.withValues(alpha: 0.2),
    child: Icon(Icons.image_outlined, color: cs.onSurfaceVariant, size: 24),
  );
}
