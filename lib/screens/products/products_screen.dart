import 'package:flutter/material.dart';
import '../../models/purchase.dart';
import '../../services/product_service.dart';
import '../../services/purchase_service.dart';
import '../../store.dart';
import 'add_product_screen.dart';
import 'all_products_screen.dart';
import '../meal_plan/shopping_list_screen.dart';
import 'fridge_search_screen.dart';
import 'fridge_item_tile.dart';
import 'all_purchases_screen.dart';
import 'purchase_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => ProductsScreenState();
}

class ProductsScreenState extends State<ProductsScreen> {
  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  static const _previewLimit = 3;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadFridge(), _loadPurchases()]);
  }

  Future<void> _loadFridge() async {
    try {
      final items = await ProductService.instance.getFridgeItems();
      if (!mounted) return;
      AppStore.instance.fridgeItems
        ..clear()
        ..addAll(items);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPurchases() async {
    try {
      final purchases = await PurchaseService.instance.getPurchases();
      if (!mounted) return;
      AppStore.instance.purchases
        ..clear()
        ..addAll(purchases);
    } catch (_) {}
  }

  Future<void> reload() async {
    setState(() => _loading = true);
    await _loadAll();
  }

  void openAddProduct() async {
    final added = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddProductScreen()));
    if (added == true) _loadFridge();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = AppStore.instance.fridgeItems;
    final purchases = AppStore.instance.purchases;
    final previewItems = items.take(_previewLimit).toList();
    final previewPurchases = purchases.take(_previewLimit).toList();

    if (_loading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _appBar(context, cs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (items.isEmpty)
                    _emptyFridge(cs)
                  else ...[
                    ...previewItems.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FridgeItemTile(
                          item: p,
                          shadow: _shadow,
                          onDeleted: () => setState(() {}),
                          onDismissed: () {
                            AppStore.instance.removeFridgeItem(p.id);
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    if (items.length > _previewLimit)
                      _seeAllButton(
                        cs,
                        label: 'Посмотреть все',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AllProductsScreen(),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Покупки',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (previewPurchases.isEmpty)
                    _emptyPurchases(cs)
                  else ...[
                    ...previewPurchases.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _purchaseCard(cs, p),
                      ),
                    ),
                    if (purchases.length > _previewLimit)
                      _seeAllButton(
                        cs,
                        label: 'Посмотреть все',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AllPurchasesScreen(),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seeAllButton(
    ColorScheme cs, {
    required String label,
    required VoidCallback onTap,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onTap,
        child: Text(label, style: TextStyle(color: cs.primary, fontSize: 14)),
      ),
    );
  }

  Widget _emptyFridge(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Холодильник пуст',
          style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _emptyPurchases(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'Список покупок пуст',
          style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Продукты',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.search, color: cs.onSurface),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FridgeSearchScreen()),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.shopping_cart_outlined,
              color: AppStore.instance.currentMealPlan != null
                  ? cs.primary
                  : cs.onSurfaceVariant,
            ),
            onPressed: () {
              final plan = AppStore.instance.currentMealPlan;
              if (plan == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Сначала создайте рацион питания'),
                  ),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ShoppingListScreen(planId: plan.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _purchaseCard(ColorScheme cs, Purchase purchase) {
    return GestureDetector(
      onTap: () async {
        final deleted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PurchaseDetailScreen(purchase: purchase),
          ),
        );
        if (deleted == true) setState(() {});
      },
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _shadow,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _PurchaseThumbnail(purchase: purchase),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${purchase.totalPrice} • ${purchase.date}',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseThumbnail extends StatelessWidget {
  final Purchase purchase;

  const _PurchaseThumbnail({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 62,
        height: 62,
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: List.generate(
            4,
            (_) => Container(
              color: cs.outline.withValues(alpha: 0.15),
              child: Icon(
                Icons.image_outlined,
                size: 14,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
