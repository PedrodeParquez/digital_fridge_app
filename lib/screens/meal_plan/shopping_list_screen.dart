import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/generated_meal_plan.dart';
import '../../services/meal_plan_service.dart';

class ShoppingListScreen extends StatefulWidget {
  final int planId;

  const ShoppingListScreen({super.key, required this.planId});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  List<ShoppingItem> _items = [];
  final Set<int> _checked = {};
  bool _loading = true;
  String? _error;

  String get _prefsKey => 'shopping_checked_${widget.planId}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await MealPlanService.instance.getShoppingList(
        widget.planId,
      );
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final savedNames = prefs.getStringList(_prefsKey)?.toSet() ?? {};
      if (!mounted) return;
      setState(() {
        _items = items;
        _checked
          ..clear()
          ..addAll([
            for (var i = 0; i < items.length; i++)
              if (savedNames.contains(items[i].productName)) i,
          ]);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить список';
        _loading = false;
      });
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, [
      for (final i in _checked) _items[i].productName,
    ]);
  }

  void _toggle(int idx) {
    setState(() {
      if (_checked.contains(idx)) {
        _checked.remove(idx);
      } else {
        _checked.add(idx);
      }
    });
    _persist();
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
          icon: Icon(Icons.arrow_back_ios_new, color: cs.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Список покупок',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            )
          : _items.isEmpty
          ? _emptyState(cs)
          : _list(cs),
    );
  }

  Widget _emptyState(ColorScheme cs) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, size: 64, color: cs.primary),
        const SizedBox(height: 16),
        Text(
          'Всё есть в холодильнике!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Все продукты для рациона уже есть',
          style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
        ),
      ],
    ),
  );

  Widget _list(ColorScheme cs) {
    final remaining = _items.length - _checked.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Осталось купить: $remaining из ${_items.length}',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        ..._items.asMap().entries.map((e) => _itemTile(cs, e.key, e.value)),
      ],
    );
  }

  Widget _itemTile(ColorScheme cs, int idx, ShoppingItem item) {
    final done = _checked.contains(idx);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _shadow,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: () => _toggle(idx),
        leading: GestureDetector(
          onTap: () => _toggle(idx),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? cs.primary : Colors.transparent,
              border: Border.all(
                color: done ? cs.primary : cs.outline,
                width: 2,
              ),
            ),
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
        title: Text(
          item.productName,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: done ? cs.onSurfaceVariant : cs.onSurface,
            decoration: done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: item.quantityInFridge > 0
            ? Text(
                'В холодильнике: ${_fmt(item.quantityInFridge)} ${item.unit}',
                style: TextStyle(fontSize: 12, color: cs.primary),
              )
            : null,
        trailing: Text(
          '${_fmt(item.quantityToBuy)} ${item.unit}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: done ? cs.onSurfaceVariant : cs.onSurface,
          ),
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
}
