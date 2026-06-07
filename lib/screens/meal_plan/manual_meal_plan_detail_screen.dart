import 'package:flutter/material.dart';
import '../../models/meal_plan.dart';
import '../../models/recipe.dart';
import '../../services/meal_plan_service.dart';
import '../../services/recipe_service.dart';
import '../../store.dart';
import '../recipes/recipe_detail_screen.dart';

class ManualMealPlanDetailScreen extends StatefulWidget {
  final MealPlan plan;

  const ManualMealPlanDetailScreen({super.key, required this.plan});

  @override
  State<ManualMealPlanDetailScreen> createState() =>
      _ManualMealPlanDetailScreenState();
}

class _ManualMealPlanDetailScreenState
    extends State<ManualMealPlanDetailScreen> {
  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  late List<DailyRation> _days;
  bool _saving = false;
  bool _hasChanges = false;

  // Слоты приёма пищи: (ключ, emoji, название)
  static const _slots = [
    ('breakfast', '🍳', 'Завтрак'),
    ('lunch', '🥗', 'Обед'),
    ('snack', '🍎', 'Перекус'),
    ('dinner', '🌙', 'Ужин'),
  ];

  @override
  void initState() {
    super.initState();
    _days = List.of(widget.plan.days);
    _ensureRecipesLoaded();
  }

  Future<void> _ensureRecipesLoaded() async {
    if (AppStore.instance.recipes.isEmpty) {
      try {
        final recipes = await RecipeService.instance.getRecipes();
        if (mounted) {
          setState(() => AppStore.instance.recipes.addAll(recipes));
        }
      } catch (_) {}
    }
  }

  int? _recipeIdForSlot(DailyRation day, String slot) => switch (slot) {
    'breakfast' => day.breakfastRecipeId,
    'lunch' => day.lunchRecipeId,
    'snack' => day.snackRecipeId,
    'dinner' => day.dinnerRecipeId,
    _ => null,
  };

  String? _nameForSlot(DailyRation day, String slot) => switch (slot) {
    'breakfast' => day.breakfast,
    'lunch' => day.lunch,
    'snack' => day.snack,
    'dinner' => day.dinner,
    _ => null,
  };

  void _setRecipe(int dayIndex, String slot, Recipe? recipe) {
    final old = _days[dayIndex];
    final updated = switch (slot) {
      'breakfast' => old.copyWith(
          breakfastRecipeId: recipe != null ? int.tryParse(recipe.id) : null,
          breakfast: recipe?.name,
        ),
      'lunch' => old.copyWith(
          lunchRecipeId: recipe != null ? int.tryParse(recipe.id) : null,
          lunch: recipe?.name,
        ),
      'snack' => old.copyWith(
          snackRecipeId: recipe != null ? int.tryParse(recipe.id) : null,
          snack: recipe?.name,
        ),
      'dinner' => old.copyWith(
          dinnerRecipeId: recipe != null ? int.tryParse(recipe.id) : null,
          dinner: recipe?.name,
        ),
      _ => old,
    };
    setState(() {
      _days[dayIndex] = updated;
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = MealPlan(
        id: widget.plan.id,
        name: widget.plan.name,
        startDate: widget.plan.startDate,
        days: _days,
      );
      await MealPlanService.instance.updateMealPlan(updated);
      if (mounted) {
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Рацион сохранён')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось сохранить'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onMealTap(int dayIndex, String slot) {
    final recipeId = _recipeIdForSlot(_days[dayIndex], slot);

    if (recipeId != null) {
      final recipe = AppStore.instance.recipes
          .cast<Recipe?>()
          .firstWhere(
            (r) => r?.id == recipeId.toString(),
            orElse: () => null,
          );
      if (recipe != null) {
        _showMealOptions(dayIndex, slot, recipe);
        return;
      }
    }
    _showRecipePicker(dayIndex, slot);
  }

  void _showMealOptions(int dayIndex, String slot, Recipe recipe) {
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
            Text(
              recipe.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.menu_book_outlined, color: cs.primary),
              title: const Text('Открыть рецепт'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(recipe: recipe),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.swap_horiz, color: cs.primary),
              title: const Text('Изменить блюдо'),
              onTap: () {
                Navigator.pop(ctx);
                _showRecipePicker(dayIndex, slot);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
              title: const Text(
                'Убрать блюдо',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _setRecipe(dayIndex, slot, null);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipePicker(int dayIndex, String slot) {
    final cs = Theme.of(context).colorScheme;
    final searchCtrl = TextEditingController();
    var filtered = List<Recipe>.of(AppStore.instance.recipes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void onSearch(String q) {
            setSheet(() {
              filtered = AppStore.instance.recipes
                  .where(
                    (r) => r.name.toLowerCase().contains(q.toLowerCase()),
                  )
                  .toList();
            });
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (_, scrollCtrl) => Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
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
                      'Выберите рецепт',
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
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.outline.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(Icons.search,
                              color: cs.onSurfaceVariant, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: searchCtrl,
                              autofocus: true,
                              onChanged: onSearch,
                              decoration: InputDecoration(
                                hintText: 'Название рецепта...',
                                hintStyle: TextStyle(
                                    color: cs.onSurfaceVariant, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(color: cs.onSurface),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'Рецепты не найдены',
                              style:
                                  TextStyle(color: cs.onSurfaceVariant),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final r = filtered[i];
                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                leading: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: r.mainImageUrl != null
                                        ? Image.network(
                                            r.mainImageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, e, s) =>
                                                    _recipePlaceholder(
                                                        cs),
                                          )
                                        : _recipePlaceholder(cs),
                                  ),
                                ),
                                title: Text(
                                  r.name,
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
                                    if (r.calories > 0)
                                      '${r.calories.toStringAsFixed(0)} ккал',
                                    r.cookTimeLabel,
                                  ].join(' · '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _setRecipe(dayIndex, slot, r);
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

  Widget _recipePlaceholder(ColorScheme cs) => Container(
        color: cs.primary.withValues(alpha: 0.08),
        child: Icon(Icons.restaurant_outlined,
            color: cs.primary, size: 22),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: cs.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.plan.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_hasChanges)
            _saving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _save,
                    child: Text(
                      'Сохранить',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (int i = 0; i < _days.length; i++)
            _dayCard(cs, i, _days[i]),
        ],
      ),
    );
  }

  Widget _dayCard(ColorScheme cs, int index, DailyRation day) {
    const weekdays = [
      'Понедельник', 'Вторник', 'Среда', 'Четверг',
      'Пятница', 'Суббота', 'Воскресенье',
    ];
    final weekday = weekdays[day.date.weekday - 1];
    final dateStr =
        '${day.date.day.toString().padLeft(2, '0')}.${day.date.month.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  weekday,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style:
                      TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Divider(
              height: 0, color: cs.outline.withValues(alpha: 0.4)),
          for (int s = 0; s < _slots.length; s++)
            _mealRow(cs, index, day, _slots[s], last: s == _slots.length - 1),
        ],
      ),
    );
  }

  Widget _mealRow(
    ColorScheme cs,
    int dayIndex,
    DailyRation day,
    (String, String, String) slot, {
    bool last = false,
  }) {
    final (key, emoji, label) = slot;
    final name = _nameForSlot(day, key);
    final recipeId = _recipeIdForSlot(day, key);
    final hasRecipe = recipeId != null;

    return Column(
      children: [
        InkWell(
          onTap: () => _onMealTap(dayIndex, key),
          borderRadius: last
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : BorderRadius.zero,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 68,
                  child: Text(
                    label,
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ),
                Expanded(
                  child: hasRecipe
                      ? Text(
                          name ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          'Не назначено',
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(width: 4),
                Icon(
                  hasRecipe
                      ? Icons.chevron_right
                      : Icons.add_circle_outline,
                  size: 18,
                  color: hasRecipe ? cs.onSurfaceVariant : cs.primary,
                ),
              ],
            ),
          ),
        ),
        if (!last)
          Divider(
            height: 0,
            color: cs.outline.withValues(alpha: 0.25),
            indent: 16,
          ),
      ],
    );
  }
}
