import 'package:flutter/material.dart';
import '../../models/preference_option.dart';
import '../../models/recipe.dart';
import '../../services/api_client.dart';
import '../../services/recipe_service.dart';
import '../../store.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  bool get _isFav =>
      AppStore.instance.favoriteRecipeIds.contains(widget.recipe.id);

  Future<void> _toggleFavorite() async {
    final wasFav = _isFav;
    setState(() => AppStore.instance.toggleFavorite(widget.recipe.id));
    try {
      await RecipeService.instance.toggleFavorite(widget.recipe.id, wasFav);
    } catch (_) {
      if (mounted)
        setState(() => AppStore.instance.toggleFavorite(widget.recipe.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = widget.recipe;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(cs, r),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statsRow(cs, r),
                  if (r.requiredEquipment.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _sectionTitle(cs, 'Необходимая техника'),
                    const SizedBox(height: 10),
                    _equipmentRow(cs, r),
                  ],
                  if (r.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _sectionTitle(cs, 'Описание'),
                    const SizedBox(height: 8),
                    Text(
                      r.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: cs.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _nutritionCard(cs, r),
                  if (r.ingredients.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _sectionTitle(cs, 'Ингредиенты'),
                    const SizedBox(height: 8),
                    _ingredientsList(cs, r),
                  ],
                  if (r.steps.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _sectionTitle(cs, 'Приготовление'),
                    const SizedBox(height: 8),
                    _stepsList(cs, r),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(ColorScheme cs, Recipe r) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: cs.surface,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _toggleFavorite,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isFav ? Icons.favorite : Icons.favorite_border,
              color: _isFav ? Colors.redAccent : Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        title: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
          child: Text(
            r.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        background: r.mainImageUrl != null
            ? Image.network(
                '${ApiClient.baseUrl}${r.mainImageUrl}',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imagePlaceholder(),
              )
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _statsRow(ColorScheme cs, Recipe r) {
    return Row(
      children: [
        _statChip(cs, Icons.timer_outlined, r.cookTimeLabel),
        const SizedBox(width: 10),
        _statChip(cs, Icons.people_outline, '${r.servings} порц.'),
        const SizedBox(width: 10),
        _statChip(cs, Icons.local_fire_department_outlined, r.caloriesLabel),
      ],
    );
  }

  Widget _statChip(ColorScheme cs, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutritionCard(ColorScheme cs, Recipe r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Пищевая ценность (на порцию)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _nutritionItem(cs, 'Белки', '${r.proteins.toStringAsFixed(1)} г'),
              _nutritionDivider(cs),
              _nutritionItem(cs, 'Жиры', '${r.fats.toStringAsFixed(1)} г'),
              _nutritionDivider(cs),
              _nutritionItem(cs, 'Углев.', '${r.carbs.toStringAsFixed(1)} г'),
              _nutritionDivider(cs),
              _nutritionItem(cs, 'Ккал', r.calories.toStringAsFixed(0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nutritionItem(ColorScheme cs, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _nutritionDivider(ColorScheme cs) {
    return Container(width: 1, height: 32, color: cs.outline);
  }

  Widget _ingredientsList(ColorScheme cs, Recipe r) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _shadow,
      ),
      child: Column(
        children: r.ingredients.asMap().entries.map((e) {
          final i = e.value;
          final isLast = e.key == r.ingredients.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        i.productName,
                        style: TextStyle(fontSize: 15, color: cs.onSurface),
                      ),
                    ),
                    Text(
                      '${i.quantity % 1 == 0 ? i.quantity.toInt() : i.quantity} ${i.unit}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 0, color: cs.outline, indent: 36),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _stepsList(ColorScheme cs, Recipe r) {
    final sorted = [...r.steps]..sort((a, b) => a.order.compareTo(b.order));
    return Column(
      children: sorted.map((step) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${step.order}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _shadow,
                  ),
                  child: Text(
                    step.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: cs.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _equipmentRow(ColorScheme cs, Recipe r) {
    final options = AppStore.instance.kitchenEquipmentOptions;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: r.requiredEquipment.map((key) {
        final opt = options.firstWhere(
          (o) => o.key == key,
          orElse: () => PreferenceOption(key: key, label: key),
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (opt.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    '${ApiClient.baseUrl}${opt.imageUrl}',
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Icon(Icons.kitchen, size: 18, color: cs.primary),
                  ),
                )
              else
                Icon(Icons.kitchen, size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                opt.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: const Color(0xFFD0E8D4),
        child: Icon(
          Icons.restaurant,
          size: 80,
          color: const Color(0xFF2E9B45).withValues(alpha: 0.3),
        ),
      );

  Widget _sectionTitle(ColorScheme cs, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: cs.onSurface,
      ),
    );
  }
}
