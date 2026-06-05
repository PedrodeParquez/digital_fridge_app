import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../store.dart';
import 'fridge_item_tile.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = AppStore.instance.fridgeItems;

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
          'Все продукты',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.kitchen_outlined, size: 64, color: cs.outline),
                  const SizedBox(height: 14),
                  Text(
                    'Холодильник пуст',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FridgeItemTile(
                  item: items[i],
                  shadow: _shadow,
                  onDeleted: () => setState(() {}),
                  onDismissed: () {
                    final id = items[i].id;
                    AppStore.instance.removeFridgeItem(id);
                    setState(() {});
                    ProductService.instance
                        .deleteFridgeItem(id)
                        .catchError((_) {});
                  },
                ),
              ),
            ),
    );
  }
}
