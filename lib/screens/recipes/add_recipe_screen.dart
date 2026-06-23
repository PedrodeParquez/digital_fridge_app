import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/preference_option.dart';
import '../../models/recipe.dart';
import '../../services/recipe_service.dart';
import '../../store.dart';

class AddRecipeScreen extends StatefulWidget {
  /// Если задан — экран работает в режиме редактирования этого рецепта.
  final Recipe? existing;

  const AddRecipeScreen({super.key, this.existing});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _carbsController = TextEditingController();
  final _timeController = TextEditingController(text: '30');
  final _servingsController = TextEditingController(text: '2');

  final List<_IngredientEntry> _ingredients = [_IngredientEntry()];
  final List<TextEditingController> _stepControllers = [
    TextEditingController(),
  ];

  final Set<String> _selectedEquipment = {};
  XFile? _imageFile;
  bool _saving = false;

  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  static const _units = ['г', 'кг', 'мл', 'л', 'шт', 'ст.л.', 'ч.л.'];

  List<PreferenceOption> get _equipmentOptions =>
      AppStore.instance.kitchenEquipmentOptions;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    if (r == null) return;
    _nameController.text = r.name;
    _descController.text = r.description;
    _caloriesController.text = _numText(r.calories);
    _proteinsController.text = _numText(r.proteins);
    _fatsController.text = _numText(r.fats);
    _carbsController.text = _numText(r.carbs);
    _timeController.text = r.cookTimeMinutes.toString();
    _servingsController.text = r.servings.toString();
    _selectedEquipment.addAll(r.requiredEquipment);
    if (r.ingredients.isNotEmpty) {
      _ingredients
        ..clear()
        ..addAll(
          r.ingredients.map((i) {
            final e = _IngredientEntry();
            e.nameController.text = i.productName;
            e.quantityController.text = _numText(i.quantity);
            e.unit = i.unit;
            return e;
          }),
        );
    }
    if (r.steps.isNotEmpty) {
      final steps = [...r.steps]..sort((a, b) => a.order.compareTo(b.order));
      _stepControllers
        ..clear()
        ..addAll(steps.map((s) => TextEditingController(text: s.description)));
    }
  }

  String _numText(num v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _caloriesController.dispose();
    _proteinsController.dispose();
    _fatsController.dispose();
    _carbsController.dispose();
    _timeController.dispose();
    _servingsController.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _imageFile = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final ingredients = _ingredients
        .where(
          (e) =>
              e.nameController.text.trim().isNotEmpty &&
              e.quantityController.text.isNotEmpty,
        )
        .map(
          (e) => RecipeIngredient(
            productName: e.nameController.text.trim(),
            quantity: double.tryParse(e.quantityController.text) ?? 0,
            unit: e.unit,
          ),
        )
        .toList();

    final steps = _stepControllers
        .asMap()
        .entries
        .where((e) => e.value.text.trim().isNotEmpty)
        .map(
          (e) => RecipeStep(order: e.key + 1, description: e.value.text.trim()),
        )
        .toList();

    final recipe = Recipe(
      id: widget.existing?.id ?? '',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      calories: double.tryParse(_caloriesController.text) ?? 0,
      proteins: double.tryParse(_proteinsController.text) ?? 0,
      fats: double.tryParse(_fatsController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      cookTimeMinutes: int.tryParse(_timeController.text) ?? 30,
      servings: int.tryParse(_servingsController.text) ?? 1,
      isPersonal: true,
      ingredients: ingredients,
      steps: steps,
      requiredEquipment: _selectedEquipment.toList(),
    );

    setState(() => _saving = true);
    try {
      final isEdit = widget.existing != null;
      final saved = isEdit
          ? await RecipeService.instance.updateRecipe(recipe)
          : await RecipeService.instance.createRecipe(recipe);
      Recipe finalRecipe = saved;
      if (_imageFile != null) {
        finalRecipe = await RecipeService.instance.uploadImage(
          saved.id,
          File(_imageFile!.path),
        );
      }
      if (isEdit) {
        AppStore.instance.updateRecipe(finalRecipe);
      } else {
        AppStore.instance.addRecipe(finalRecipe);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось сохранить рецепт: ${_apiError(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _apiError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      final body = e.response?.data;
      if (code != null) return 'код $code${body != null ? ' — $body' : ''}';
      return e.message ?? 'нет соединения с сервером';
    }
    return e.toString();
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
          widget.existing != null ? 'Редактировать рецепт' : 'Новый рецепт',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(cs, 'Фото'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cs.outline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cs.outline.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.file(
                            File(_imageFile!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 36,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Добавить фото',
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel(cs, 'Основное'),
              const SizedBox(height: 8),
              _card(
                cs,
                child: Column(
                  children: [
                    _cardField(
                      cs,
                      controller: _nameController,
                      hint: 'Название рецепта',
                      showDivider: true,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Введите название'
                          : null,
                    ),
                    _cardField(
                      cs,
                      controller: _descController,
                      hint: 'Описание (необязательно)',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(cs, 'Время (мин)'),
                        const SizedBox(height: 6),
                        _inputCard(
                          cs,
                          child: TextFormField(
                            controller: _timeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: TextStyle(color: cs.onSurface),
                            decoration: InputDecoration(
                              hintText: '30',
                              hintStyle: TextStyle(color: cs.onSurfaceVariant),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
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
                        _label(cs, 'Порций'),
                        const SizedBox(height: 6),
                        _inputCard(
                          cs,
                          child: TextFormField(
                            controller: _servingsController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: TextStyle(color: cs.onSurface),
                            decoration: InputDecoration(
                              hintText: '2',
                              hintStyle: TextStyle(color: cs.onSurfaceVariant),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sectionLabel(cs, 'Пищевая ценность (на порцию)'),
              const SizedBox(height: 8),
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
              if (_equipmentOptions.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionLabel(cs, 'Необходимая техника'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _equipmentOptions.map((opt) {
                    final selected = _selectedEquipment.contains(opt.key);
                    return GestureDetector(
                      onTap: () => setState(() {
                        selected
                            ? _selectedEquipment.remove(opt.key)
                            : _selectedEquipment.add(opt.key);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primary.withValues(alpha: 0.12)
                              : cs.outline.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? cs.primary : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: selected ? cs.primary : cs.onSurface,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              _sectionLabel(cs, 'Ингредиенты'),
              const SizedBox(height: 8),
              ..._ingredients.asMap().entries.map(
                (e) => _IngredientRow(
                  key: ValueKey('ingredient_${e.key}'),
                  entry: e.value,
                  units: _units,
                  shadow: _shadow,
                  showDelete: _ingredients.length > 1,
                  onDelete: () => setState(() => _ingredients.removeAt(e.key)),
                  onUnitChanged: (u) =>
                      setState(() => _ingredients[e.key].unit = u),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _ingredients.add(_IngredientEntry())),
                icon: Icon(Icons.add, color: cs.primary, size: 18),
                label: Text(
                  'Добавить ингредиент',
                  style: TextStyle(color: cs.primary, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              _sectionLabel(cs, 'Шаги приготовления'),
              const SizedBox(height: 8),
              ..._stepControllers.asMap().entries.map(
                (e) => _StepRow(
                  key: ValueKey('step_${e.key}'),
                  index: e.key,
                  controller: e.value,
                  shadow: _shadow,
                  showDelete: _stepControllers.length > 1,
                  onDelete: () {
                    e.value.dispose();
                    setState(() => _stepControllers.removeAt(e.key));
                  },
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(
                  () => _stepControllers.add(TextEditingController()),
                ),
                icon: Icon(Icons.add, color: cs.primary, size: 18),
                label: Text(
                  'Добавить шаг',
                  style: TextStyle(color: cs.primary, fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Сохранить рецепт',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _sectionLabel(ColorScheme cs, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: cs.onSurface,
    ),
  );

  Widget _label(ColorScheme cs, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: cs.onSurfaceVariant,
    ),
  );

  Widget _card(ColorScheme cs, {required Widget child}) => Container(
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      boxShadow: _shadow,
    ),
    child: child,
  );

  Widget _inputCard(ColorScheme cs, {required Widget child}) => Container(
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      boxShadow: _shadow,
    ),
    child: child,
  );

  Widget _cardField(
    ColorScheme cs, {
    required TextEditingController controller,
    required String hint,
    bool showDivider = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: cs.onSurfaceVariant),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: validator,
        ),
        if (showDivider)
          Divider(color: Theme.of(context).dividerColor, height: 0),
      ],
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

class _IngredientEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  String unit = 'г';
}

class _IngredientRow extends StatelessWidget {
  final _IngredientEntry entry;
  final List<String> units;
  final List<BoxShadow> shadow;
  final bool showDelete;
  final VoidCallback onDelete;
  final void Function(String) onUnitChanged;

  const _IngredientRow({
    super.key,
    required this.entry,
    required this.units,
    required this.shadow,
    required this.showDelete,
    required this.onDelete,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: shadow,
              ),
              child: TextField(
                controller: entry.nameController,
                style: TextStyle(color: cs.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ингредиент',
                  hintStyle: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 60,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: shadow,
              ),
              child: TextField(
                controller: entry.quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                style: TextStyle(color: cs.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '100',
                  hintStyle: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: shadow,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: entry.unit,
                style: TextStyle(color: cs.onSurface, fontSize: 13),
                items: units
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => onUnitChanged(v!),
              ),
            ),
          ),
          if (showDelete)
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final List<BoxShadow> shadow;
  final bool showDelete;
  final VoidCallback onDelete;

  const _StepRow({
    super.key,
    required this.index,
    required this.controller,
    required this.shadow,
    required this.showDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: shadow,
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                style: TextStyle(color: cs.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Опишите шаг приготовления',
                  hintStyle: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          if (showDelete)
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
