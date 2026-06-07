import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/fridge_item.dart';
import '../../services/open_food_facts_service.dart';
import '../../services/product_service.dart';
import 'barcode_scanner_screen.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _carbsController = TextEditingController();

  String _unit = 'г';
  DateTime? _expiryDate;
  bool _showNutrition = false;
  File? _photo;
  String _imageUrl = '';

  static const _units = ['г', 'кг', 'мл', 'л', 'шт'];

  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _caloriesController.dispose();
    _proteinsController.dispose();
    _fatsController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final item = FridgeItem(
      id: '',
      productName: _nameController.text.trim(),
      quantity: double.tryParse(_quantityController.text) ?? 0,
      unit: _unit,
      expiryDate: _expiryDate,
      calories: double.tryParse(_caloriesController.text) ?? 0,
      proteins: double.tryParse(_proteinsController.text) ?? 0,
      fats: double.tryParse(_fatsController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      imageUrl: _imageUrl,
    );
    try {
      await ProductService.instance.addFridgeItem(item);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _fillFromProduct(FoodProduct product) {
    _nameController.text = product.name;
    if (product.calories > 0) {
      _caloriesController.text = product.calories.toStringAsFixed(1);
    }
    if (product.proteins > 0) {
      _proteinsController.text = product.proteins.toStringAsFixed(1);
    }
    if (product.fats > 0) {
      _fatsController.text = product.fats.toStringAsFixed(1);
    }
    if (product.carbs > 0) {
      _carbsController.text = product.carbs.toStringAsFixed(1);
    }
    final hasNutrition =
        product.calories > 0 ||
        product.proteins > 0 ||
        product.fats > 0 ||
        product.carbs > 0;
    setState(() {
      _showNutrition = hasNutrition;
      _imageUrl = product.imageUrl;
      _photo = null;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  void _showPhotoOptions() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt_outlined, color: cs.primary),
              ),
              title: const Text('Сфотографировать'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library_outlined, color: cs.primary),
              ),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photo != null)
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                title: const Text(
                  'Удалить фото',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _photo = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBarcodeScanner() async {
    final product = await Navigator.of(context).push<FoodProduct>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (product != null) _fillFromProduct(product);
  }

  Future<void> _showProductSearch() async {
    final cs = Theme.of(context).colorScheme;
    final searchCtrl = TextEditingController();
    List<FoodProduct> results = [];
    bool searching = false;
    String? error;
    Timer? debounce;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> doSearch(String q) async {
            if (q.trim().isEmpty) {
              setSheet(() {
                results = [];
                error = null;
                searching = false;
              });
              return;
            }
            setSheet(() {
              searching = true;
              error = null;
            });
            try {
              final found = await OpenFoodFactsService.instance.search(
                q.trim(),
              );
              setSheet(() {
                results = found;
                searching = false;
              });
            } catch (_) {
              setSheet(() {
                error = 'Не удалось загрузить результаты. Попробуйте ещё раз.';
                searching = false;
              });
            }
          }

          void onChanged(String q) {
            debounce?.cancel();
            debounce = Timer(
              const Duration(milliseconds: 600),
              () => doSearch(q),
            );
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (_, scrollCtrl) => Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Поиск продукта',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: cs.outline.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(
                            Icons.search,
                            color: cs.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: searchCtrl,
                              autofocus: true,
                              onChanged: onChanged,
                              decoration: InputDecoration(
                                hintText: 'Например: Гречка, Молоко...',
                                hintStyle: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(color: cs.onSurface),
                            ),
                          ),
                          if (searching)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.primary,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: error != null
                        ? Center(
                            child: Text(
                              error!,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          )
                        : results.isEmpty && !searching
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search, size: 48, color: cs.outline),
                                const SizedBox(height: 12),
                                Text(
                                  'Начните вводить название продукта',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: results.length,
                            itemBuilder: (_, i) {
                              final p = results[i];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: p.imageUrl.isNotEmpty
                                        ? Image.network(
                                            p.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, e, s) =>
                                                _productPlaceholder(cs),
                                            loadingBuilder:
                                                (_, child, progress) =>
                                                    progress == null
                                                    ? child
                                                    : _productPlaceholder(cs),
                                          )
                                        : _productPlaceholder(cs),
                                  ),
                                ),
                                title: Text(
                                  p.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  [
                                    if (p.brand.isNotEmpty) p.brand,
                                    if (p.quantity != null &&
                                        p.quantity!.isNotEmpty)
                                      p.quantity!,
                                    if (p.calories > 0)
                                      '${p.calories.toStringAsFixed(0)} ккал/100г',
                                  ].join(' · '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _fillFromProduct(p);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      locale: const Locale('ru'),
    );
    if (picked != null) setState(() => _expiryDate = picked);
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
          'Добавить продукт',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _showProductSearch,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search, color: cs.onSurfaceVariant, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Найти продукт',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.qr_code_scanner,
                          color: cs.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: _openBarcodeScanner,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _showPhotoOptions,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _shadow,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _photo != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_photo!, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _photo = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _imageUrl.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              _imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, e, s) =>
                                  _photoPlaceholder(cs),
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                  ? child
                                  : _photoPlaceholder(cs),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageUrl = ''),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_a_photo_outlined,
                                color: cs.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Добавить фото',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Камера или галерея',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              _label(cs, 'Название продукта'),
              const SizedBox(height: 6),
              _inputCard(
                cs,
                child: TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Например: Куриное филе',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Введите название'
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(cs, 'Количество'),
                        const SizedBox(height: 6),
                        _inputCard(
                          cs,
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'),
                              ),
                            ],
                            style: TextStyle(color: cs.onSurface),
                            decoration: InputDecoration(
                              hintText: '100',
                              hintStyle: TextStyle(color: cs.onSurfaceVariant),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Укажите' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(cs, 'Единица'),
                        const SizedBox(height: 6),
                        _dropdownCard(
                          cs,
                          value: _unit,
                          items: _units,
                          onChanged: (v) => setState(() => _unit = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label(cs, 'Срок годности'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickExpiryDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _shadow,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: cs.onSurfaceVariant,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _expiryDate == null
                            ? 'Выбрать дату'
                            : '${_expiryDate!.day.toString().padLeft(2, '0')}.${_expiryDate!.month.toString().padLeft(2, '0')}.${_expiryDate!.year}',
                        style: TextStyle(
                          color: _expiryDate == null
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      if (_expiryDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _expiryDate = null),
                          child: Icon(
                            Icons.close,
                            color: cs.onSurfaceVariant,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _showNutrition = !_showNutrition),
                child: Row(
                  children: [
                    Text(
                      'Пищевая ценность (на 100 г)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _showNutrition
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              if (_showNutrition) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    _nutritionField(cs, _caloriesController, 'Ккал'),
                    const SizedBox(width: 8),
                    _nutritionField(cs, _proteinsController, 'Белки, г'),
                    const SizedBox(width: 8),
                    _nutritionField(cs, _fatsController, 'Жиры, г'),
                    const SizedBox(width: 8),
                    _nutritionField(cs, _carbsController, 'Углев., г'),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Добавить продукт',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productPlaceholder(ColorScheme cs) {
    return Container(
      color: cs.primary.withValues(alpha: 0.08),
      child: Icon(Icons.fastfood_outlined, color: cs.primary, size: 22),
    );
  }

  Widget _photoPlaceholder(ColorScheme cs) {
    return Container(
      color: cs.outline.withValues(alpha: 0.1),
      child: Icon(Icons.image_outlined, color: cs.onSurfaceVariant, size: 32),
    );
  }

  Widget _label(ColorScheme cs, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: cs.onSurfaceVariant,
      ),
    );
  }

  Widget _inputCard(ColorScheme cs, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _shadow,
      ),
      child: child,
    );
  }

  Widget _dropdownCard(
    ColorScheme cs, {
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _shadow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: TextStyle(color: cs.onSurface, fontSize: 15),
          items: items
              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _nutritionField(
    ColorScheme cs,
    TextEditingController controller,
    String label,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: _shadow,
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              style: TextStyle(color: cs.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: cs.onSurfaceVariant),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
