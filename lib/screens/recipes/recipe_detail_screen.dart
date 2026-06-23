import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/preference_option.dart';
import '../../models/recipe.dart';
import '../../services/api_client.dart';
import '../../services/recipe_service.dart';
import '../../store.dart';
import 'add_recipe_screen.dart';

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

  late Recipe _recipe;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
  }

  bool get _isFav => AppStore.instance.favoriteRecipeIds.contains(_recipe.id);

  Future<void> _toggleFavorite() async {
    final wasFav = _isFav;
    setState(() => AppStore.instance.toggleFavorite(_recipe.id));
    try {
      await RecipeService.instance.toggleFavorite(_recipe.id, wasFav);
    } catch (_) {
      if (mounted) {
        setState(() => AppStore.instance.toggleFavorite(_recipe.id));
      }
    }
  }

  void _showRecipeMenu() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.edit_outlined, color: cs.primary),
                title: const Text('Редактировать'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editRecipe();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Удалить',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteRecipe();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editRecipe() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddRecipeScreen(existing: _recipe)),
    );
    if (updated == true && mounted) {
      final fresh = AppStore.instance.recipes.firstWhere(
        (r) => r.id == _recipe.id,
        orElse: () => _recipe,
      );
      setState(() => _recipe = fresh);
    }
  }

  Future<void> _deleteRecipe() async {
    try {
      await RecipeService.instance.deleteRecipe(_recipe.id);
      AppStore.instance.removeRecipe(_recipe.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось удалить рецепт'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showImageOptions() async {
    final hasImage = _recipe.mainImageUrl != null;
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(hasImage ? 'Изменить фото' : 'Загрузить фото'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage();
              },
            ),
            if (hasImage)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Удалить фото',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteCurrentImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    try {
      final updated = await RecipeService.instance.uploadImage(
        _recipe.id,
        File(picked.path),
      );
      setState(() => _recipe = updated);
      AppStore.instance.updateRecipe(updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось загрузить фото')),
        );
      }
    }
  }

  Future<void> _deleteCurrentImage() async {
    if (_recipe.images.isEmpty) return;
    final image = [..._recipe.images]
      ..sort((a, b) => a.order.compareTo(b.order));
    final main = image.first;
    try {
      await RecipeService.instance.deleteImage(_recipe.id, main.id.toString());
      final remaining = _recipe.images.where((i) => i.id != main.id).toList();
      final updated = Recipe(
        id: _recipe.id,
        name: _recipe.name,
        description: _recipe.description,
        calories: _recipe.calories,
        proteins: _recipe.proteins,
        fats: _recipe.fats,
        carbs: _recipe.carbs,
        servings: _recipe.servings,
        cookTimeMinutes: _recipe.cookTimeMinutes,
        isPersonal: _recipe.isPersonal,
        ingredients: _recipe.ingredients,
        steps: _recipe.steps,
        images: remaining,
        requiredEquipment: _recipe.requiredEquipment,
      );
      setState(() => _recipe = updated);
      AppStore.instance.updateRecipe(updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось удалить фото')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = _recipe;

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
        if (!r.isPersonal)
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
        if (r.isPersonal)
          GestureDetector(
            onTap: _showRecipeMenu,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
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
        background: Stack(
          fit: StackFit.expand,
          children: [
            r.mainImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: '${ApiClient.baseUrl}${r.mainImageUrl}',
                    fit: BoxFit.cover,
                    placeholder: (_, url) => _imagePlaceholder(),
                    errorWidget: (_, url, e) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
            if (r.isPersonal)
              Positioned(
                bottom: 48,
                right: 12,
                child: GestureDetector(
                  onTap: _showImageOptions,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
                    errorBuilder: (_, e, s) =>
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
