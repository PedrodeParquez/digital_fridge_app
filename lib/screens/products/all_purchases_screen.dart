import 'package:flutter/material.dart';
import '../../models/purchase.dart';
import '../../store.dart';
import 'purchase_detail_screen.dart';

class AllPurchasesScreen extends StatefulWidget {
  const AllPurchasesScreen({super.key});

  @override
  State<AllPurchasesScreen> createState() => _AllPurchasesScreenState();
}

class _AllPurchasesScreenState extends State<AllPurchasesScreen> {
  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final purchases = AppStore.instance.purchases;

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
          'Все покупки',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: purchases.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _purchaseCard(ctx, cs, purchases[i]),
        ),
      ),
    );
  }

  Widget _purchaseCard(
    BuildContext context,
    ColorScheme cs,
    Purchase purchase,
  ) {
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
                    const SizedBox(height: 2),
                    Text(
                      '${purchase.itemsCount} товаров',
                      style: TextStyle(
                        fontSize: 12,
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
