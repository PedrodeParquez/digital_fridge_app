import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/fridge_item.dart';
import '../../models/purchase.dart';
import '../../services/product_service.dart';
import '../../services/purchase_service.dart';
import '../../services/receipt_service.dart';
import '../../store.dart';
import 'product_sheet.dart';

class AddPurchaseScreen extends StatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  bool _scanning = true;
  bool _loading = false;
  String? _error;
  ReceiptData? _receipt;
  final Set<int> _selectedItems = {};
  bool _scannedOnce = false;
  String? _lastScanned;

  void _onDetect(BarcodeCapture capture) async {
    if (_scannedOnce || _loading) return;
    final qr = capture.barcodes.firstOrNull?.rawValue;
    if (qr == null) return;

    setState(() => _lastScanned = qr);

    if (!qr.contains('fn=')) {
      setState(
        () => _error =
            'Это не QR-код кассового чека.\nОтсканируйте QR с фискального чека.',
      );
      return;
    }

    _scannedOnce = true;
    setState(() {
      _loading = true;
      _error = null;
      _scanning = false;
    });

    try {
      final receipt = await ReceiptService.instance.fetchByQr(qr);
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _loading = false;
        _selectedItems.addAll(List.generate(receipt.items.length, (i) => i));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final receipt = _receipt;
    if (receipt == null) return;

    final selected = receipt.items
        .asMap()
        .entries
        .where((e) => _selectedItems.contains(e.key))
        .map((e) => e.value)
        .toList();

    final total = selected.fold(0.0, (s, i) => s + i.sumRub);
    final d = receipt.dateTime;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

    final purchase = Purchase(
      id: '',
      name: receipt.shopName,
      totalPrice: '${total.toStringAsFixed(2)} ₽',
      date: dateStr,
      type: PurchaseType.store,
      items: selected
          .map(
            (i) => PurchaseItem(
              name: i.name,
              quantity: i.quantity,
              unit: 'шт',
              price: '${i.priceRub.toStringAsFixed(2)} ₽',
            ),
          )
          .toList(),
    );

    setState(() => _loading = true);

    try {
      final saved = await PurchaseService.instance.createPurchase(purchase);
      AppStore.instance.purchases.add(saved);
    } catch (_) {
      AppStore.instance.purchases.add(purchase);
    }

    final futures = selected.map((item) async {
      final off = await searchNutrition(item.name);

      final fridgeItem = FridgeItem(
        id: '',
        productName: item.name,
        quantity: item.quantity,
        unit: 'шт',
        calories: off?.calories ?? 0,
        proteins: off?.proteins ?? 0,
        fats: off?.fats ?? 0,
        carbs: off?.carbs ?? 0,
        imageUrl: off?.imageUrl ?? '',
      );

      try {
        final saved = await ProductService.instance.addFridgeItem(fridgeItem);
        AppStore.instance.addFridgeItem(saved);
      } catch (_) {
        AppStore.instance.addFridgeItem(fridgeItem);
      }
    }).toList();

    await Future.wait(futures);

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _receipt != null ? 'Чек получен' : 'Сканировать чек',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_receipt != null)
            TextButton(
              onPressed: _loading ? null : _save,
              child: Text(
                'Сохранить',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
      body: _receipt != null ? _receiptPreview(cs) : _scannerView(cs),
    );
  }

  Widget _scannerView(ColorScheme cs) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              if (_scanning)
                MobileScanner(onDetect: _onDetect)
              else
                Container(color: Colors.black),
              if (_scanning)
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.primary, width: 2.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              if (_loading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: _error != null
              ? Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade400,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurface, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _error = null;
                        _scanning = true;
                        _scannedOnce = false;
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Попробовать снова'),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: cs.onSurfaceVariant,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Наведите камеру на QR-код\nна кассовом чеке',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    if (_lastScanned != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Отсканировано: ${_lastScanned!.length > 40 ? '${_lastScanned!.substring(0, 40)}…' : _lastScanned!}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _receiptPreview(ColorScheme cs) {
    final receipt = _receipt!;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.store_outlined, color: cs.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.shopName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    if (receipt.address.isNotEmpty)
                      Text(
                        receipt.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                '${receipt.totalRub.toStringAsFixed(2)} ₽',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Товары (${receipt.items.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  if (_selectedItems.length == receipt.items.length) {
                    _selectedItems.clear();
                  } else {
                    _selectedItems.addAll(
                      List.generate(receipt.items.length, (i) => i),
                    );
                  }
                }),
                child: Text(
                  _selectedItems.length == receipt.items.length
                      ? 'Снять все'
                      : 'Выбрать все',
                  style: TextStyle(color: cs.primary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: receipt.items.length,
            itemBuilder: (_, i) {
              final item = receipt.items[i];
              final selected = _selectedItems.contains(i);
              return GestureDetector(
                onTap: () => setState(() {
                  selected ? _selectedItems.remove(i) : _selectedItems.add(i);
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _shadow,
                    border: Border.all(
                      color: selected
                          ? cs.primary.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? cs.primary : Colors.transparent,
                          border: Border.all(
                            color: selected ? cs.primary : cs.outline,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} × ${item.priceRub.toStringAsFixed(2)} ₽',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${item.sumRub.toStringAsFixed(2)} ₽',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading || _selectedItems.isEmpty ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Добавить ${_selectedItems.length} позиц.',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
