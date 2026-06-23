import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../services/api_client.dart';
import '../../services/preferences_service.dart';
import '../../services/recipe_service.dart';
import '../../store.dart';
import '../profile/profile_screen.dart';
import 'add_recipe_screen.dart';
import 'my_recipes_screen.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => RecipesScreenState();
}

enum _SortBy { none, name, calories, time }

class RecipesScreenState extends State<RecipesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _loading = true;
  int? _maxTimeFilter;
  _SortBy _sortBy = _SortBy.none;
  String? _equipmentFilter;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    try {
      final recipes = RecipeService.instance.getRecipes();
      final personal = RecipeService.instance.getPersonalRecipes().catchError(
        (_) => <Recipe>[],
      );
      final favIds = RecipeService.instance.getFavoriteIds();
      final prefs = PreferencesService.instance.getPreferences();
      final options = PreferencesService.instance.getOptions();

      // Личные рецепты приходят с отдельного эндпоинта; объединяем оба
      // списка по id, чтобы созданный рецепт не пропадал из «Моих рецептов».
      final byId = <String, Recipe>{};
      for (final r in await recipes) {
        byId[r.id] = r;
      }
      for (final r in await personal) {
        byId[r.id] = r;
      }
      AppStore.instance.recipes
        ..clear()
        ..addAll(byId.values);
      AppStore.instance.favoriteRecipeIds
        ..clear()
        ..addAll(await favIds);
      AppStore.instance.preferences = await prefs;
      AppStore.instance.preferencesOptions = await options;
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite(String id) async {
    final wasFav = AppStore.instance.favoriteRecipeIds.contains(id);
    setState(() => AppStore.instance.toggleFavorite(id));
    try {
      await RecipeService.instance.toggleFavorite(id, wasFav);
    } catch (_) {
      // откатываем локальное изменение, если сервер не принял
      if (mounted) setState(() => AppStore.instance.toggleFavorite(id));
    }
  }

  void openAddRecipe() async {
    final added = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddRecipeScreen()));
    if (added == true) _loadRecipes();
  }

  List<Recipe> get _myRecipes => AppStore.instance.myRecipes
      .where(
        (r) =>
            _query.isEmpty ||
            r.name.toLowerCase().contains(_query.toLowerCase()),
      )
      .toList();

  List<Recipe> get _recommendations {
    final prefs = AppStore.instance.preferences;
    final intolerances = (prefs?.intolerances ?? [])
        .map((s) => s.toLowerCase())
        .toList();
    final calorieLimit = prefs?.calorieLimit?.toDouble();

    var list = AppStore.instance.recommendations.where((r) {
      if (_query.isNotEmpty &&
          !r.name.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      if (_maxTimeFilter != null && r.cookTimeMinutes > _maxTimeFilter!) {
        return false;
      }
      if (calorieLimit != null && r.calories > calorieLimit) {
        return false;
      }
      if (intolerances.isNotEmpty) {
        final ingredientText = r.ingredients
            .map((i) => i.productName.toLowerCase())
            .join(' ');
        if (intolerances.any((intol) => ingredientText.contains(intol))) {
          return false;
        }
      }
      if (_equipmentFilter != null &&
          r.requiredEquipment.isNotEmpty &&
          !r.requiredEquipment.contains(_equipmentFilter)) {
        return false;
      }
      return true;
    }).toList();
    switch (_sortBy) {
      case _SortBy.name:
        list.sort((a, b) => a.name.compareTo(b.name));
      case _SortBy.calories:
        list.sort((a, b) => a.calories.compareTo(b.calories));
      case _SortBy.time:
        list.sort((a, b) => a.cookTimeMinutes.compareTo(b.cookTimeMinutes));
      case _SortBy.none:
        final favProducts = (prefs?.favoriteProducts ?? [])
            .map((s) => s.toLowerCase())
            .toList();
        if (favProducts.isNotEmpty) {
          list.sort(
            (a, b) => _favScore(b, favProducts) - _favScore(a, favProducts),
          );
        }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _searchBar(context),
            const SizedBox(height: 20),
            _section(
              context,
              title: 'Мои рецепты',
              onSeeAll: _myRecipes.isNotEmpty
                  ? () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MyRecipesScreen(),
                        ),
                      );
                      setState(() {});
                    }
                  : null,
              child: _myRecipes.isNotEmpty
                  ? SizedBox(
                      height: 210,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _myRecipes.length,
                        itemBuilder: (ctx, i) => _RecipeCard(
                          recipe: _myRecipes[i],
                          width: 155,
                          showFavorite: false,
                          onFavoriteToggle: () =>
                              _toggleFavorite(_myRecipes[i].id),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    RecipeDetailScreen(recipe: _myRecipes[i]),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _addRecipeButton(context),
                    ),
            ),
            const SizedBox(height: 20),
            _section(
              context,
              title: 'Рекомендации',
              child: _recommendations.isEmpty
                  ? _emptyRecommendations(context)
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                        itemCount: _recommendations.length,
                        itemBuilder: (ctx, i) => _RecipeCard(
                          recipe: _recommendations[i],
                          onFavoriteToggle: () =>
                              _toggleFavorite(_recommendations[i].id),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(
                                recipe: _recommendations[i],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  int _favScore(Recipe r, List<String> favProducts) {
    final text = r.ingredients
        .map((i) => i.productName.toLowerCase())
        .join(' ');
    return favProducts.where((p) => text.contains(p)).length;
  }

  Widget _emptyRecommendations(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu_outlined, size: 48, color: cs.outline),
          const SizedBox(height: 12),
          Text(
            'Заполните профиль для получения\nрекомендаций',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
              _loadRecipes();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: Text(
              'Перейти в профиль',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addRecipeButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: openAddRecipe,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Добавить свой первый рецепт',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Время приготовления',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip(cs, setSheet, 'Любое', null, _maxTimeFilter),
                      _filterChip(cs, setSheet, '≤ 15 мин', 15, _maxTimeFilter),
                      _filterChip(cs, setSheet, '≤ 30 мин', 30, _maxTimeFilter),
                      _filterChip(cs, setSheet, '≤ 60 мин', 60, _maxTimeFilter),
                    ],
                  ),
                  if (AppStore.instance.kitchenEquipmentOptions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Кухонная техника',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _equipmentChip(cs, setSheet, 'Любая', null),
                        ...AppStore.instance.kitchenEquipmentOptions.map(
                          (opt) =>
                              _equipmentChip(cs, setSheet, opt.label, opt.key),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Сортировка',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _sortChip(cs, setSheet, 'По умолчанию', _SortBy.none),
                      _sortChip(cs, setSheet, 'По названию', _SortBy.name),
                      _sortChip(cs, setSheet, 'По калориям', _SortBy.calories),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Применить',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _filterChip(
    ColorScheme cs,
    StateSetter setSheet,
    String label,
    int? value,
    int? current,
  ) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => setSheet(() => _maxTimeFilter = value),
      child: Chip(
        label: Text(label),
        backgroundColor: selected
            ? cs.primary
            : cs.outline.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: selected ? Colors.white : cs.onSurface,
          fontSize: 13,
        ),
        side: BorderSide.none,
      ),
    );
  }

  Widget _sortChip(
    ColorScheme cs,
    StateSetter setSheet,
    String label,
    _SortBy value,
  ) {
    final selected = _sortBy == value;
    return GestureDetector(
      onTap: () => setSheet(() => _sortBy = value),
      child: Chip(
        label: Text(label),
        backgroundColor: selected
            ? cs.primary
            : cs.outline.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: selected ? Colors.white : cs.onSurface,
          fontSize: 13,
        ),
        side: BorderSide.none,
      ),
    );
  }

  Widget _equipmentChip(
    ColorScheme cs,
    StateSetter setSheet,
    String label,
    String? value,
  ) {
    final selected = _equipmentFilter == value;
    return GestureDetector(
      onTap: () => setSheet(() => _equipmentFilter = value),
      child: Chip(
        label: Text(label),
        backgroundColor: selected
            ? cs.primary
            : cs.outline.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: selected ? Colors.white : cs.onSurface,
          fontSize: 13,
        ),
        side: BorderSide.none,
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Поиск рецептов',
                  hintStyle: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(color: cs.onSurface),
              ),
            ),
            if (_query.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close, color: cs.onSurfaceVariant, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              )
            else
              IconButton(
                icon: Icon(
                  Icons.tune,
                  color: (_maxTimeFilter != null || _sortBy != _SortBy.none)
                      ? cs.primary
                      : cs.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () => _showFilterSheet(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required Widget child,
    VoidCallback? onSeeAll,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'Посмотреть все',
                    style: TextStyle(color: cs.primary, fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final double? width;
  final VoidCallback onFavoriteToggle;
  final bool showFavorite;
  final VoidCallback? onTap;

  const _RecipeCard({
    required this.recipe,
    required this.onFavoriteToggle,
    this.width,
    this.showFavorite = true,
    this.onTap,
  });

  static const _shadow = [
    BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4)),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFav = AppStore.instance.favoriteRecipeIds.contains(recipe.id);

    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: _shadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  recipe.mainImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl:
                              '${ApiClient.baseUrl}${recipe.mainImageUrl}',
                          fit: BoxFit.cover,
                          placeholder: (_, url) => _recipePlaceholder(cs),
                          errorWidget: (_, url, e) => _recipePlaceholder(cs),
                        )
                      : _recipePlaceholder(cs),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        recipe.cookTimeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (showFavorite)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onFavoriteToggle,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          recipe.name,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          recipe.caloriesLabel,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );

    final wrapped = GestureDetector(onTap: onTap, child: card);

    if (width != null) {
      return Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
        child: wrapped,
      );
    }
    return wrapped;
  }

  Widget _recipePlaceholder(ColorScheme cs) => Container(
    color: cs.outline.withValues(alpha: 0.25),
    child: Icon(Icons.restaurant, color: cs.onSurfaceVariant, size: 36),
  );
}
