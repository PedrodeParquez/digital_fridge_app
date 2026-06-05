import 'package:flutter/material.dart';
import '../../models/fridge_item.dart';
import '../../store.dart';
import 'fridge_item_tile.dart';

class FridgeSearchScreen extends StatefulWidget {
  const FridgeSearchScreen({super.key});

  @override
  State<FridgeSearchScreen> createState() => _FridgeSearchScreenState();
}

class _FridgeSearchScreenState extends State<FridgeSearchScreen> {
  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  final _controller = TextEditingController();
  List<FridgeItem> _results = [];

  @override
  void initState() {
    super.initState();
    _results = AppStore.instance.fridgeItems.toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _results = q.isEmpty
          ? AppStore.instance.fridgeItems.toList()
          : AppStore.instance.fridgeItems
              .where((item) => item.productName.toLowerCase().contains(q))
              .toList();
    });
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
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: cs.outline.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Icon(Icons.search, color: cs.onSurfaceVariant, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: 'Найти в холодильнике...',
                    hintStyle:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(color: cs.onSurface, fontSize: 15),
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.close, color: cs.onSurfaceVariant, size: 18),
                  onPressed: () {
                    _controller.clear();
                    _onChanged('');
                  },
                ),
            ],
          ),
        ),
      ),
      body: _results.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 56, color: cs.outline),
                  const SizedBox(height: 14),
                  Text(
                    _controller.text.isEmpty
                        ? 'Холодильник пуст'
                        : 'Ничего не найдено',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  if (_controller.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Попробуйте другой запрос',
                      style:
                          TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FridgeItemTile(
                  item: _results[i],
                  shadow: _shadow,
                  onDeleted: () => setState(() => _onChanged(_controller.text)),
                  onDismissed: () {
                    final id = _results[i].id;
                    AppStore.instance.removeFridgeItem(id);
                    setState(() => _onChanged(_controller.text));
                  },
                ),
              ),
            ),
    );
  }
}
