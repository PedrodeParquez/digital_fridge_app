import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/diary.dart';
import '../../models/generated_meal_plan.dart';
import '../../services/diary_service.dart';
import '../../services/meal_plan_service.dart';
import '../../services/user_service.dart';
import '../../store.dart';
import '../meal_plan/meal_plan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  bool _loading = true;

  static const _mealTypes = [
    ('breakfast', '🍳', 'Завтрак'),
    ('lunch', '🥗', 'Обед'),
    ('snack', '🍎', 'Перекус'),
    ('dinner', '🌙', 'Ужин'),
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> reload() async {
    if (AppStore.instance.currentMealPlan == null) {
      final plan = await MealPlanService.instance.loadPlanLocally();
      if (plan != null) AppStore.instance.currentMealPlan = plan;
    }
    await _loadDiary();
    if (mounted) setState(() {});
  }

  Future<void> _loadAll() async {
    if (AppStore.instance.currentMealPlan == null) {
      final plan = await MealPlanService.instance.loadPlanLocally();
      if (plan != null) AppStore.instance.currentMealPlan = plan;
    }
    await Future.wait([_loadUser(), _loadDiary()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadUser() async {
    try {
      final profile =
          UserService.instance.cached ??
          await UserService.instance.getProfile();
      if (mounted) setState(() => _userName = profile.name);
    } catch (_) {}
  }

  Future<void> _loadDiary() async {
    try {
      final targets = DiaryService.instance.getDailyTargets();
      final diary = DiaryService.instance.getTodayDiary();
      AppStore.instance.dailyTargets = await targets;
      AppStore.instance.todayDiary = await diary;
    } catch (_) {}
  }

  Future<void> _reload() async {
    try {
      final diary = await DiaryService.instance.getTodayDiary();
      if (mounted) {
        AppStore.instance.todayDiary = diary;
        setState(() {});
      }
    } catch (_) {}
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Доброе утро';
    if (h >= 12 && h < 17) return 'Добрый день';
    if (h >= 17 && h < 22) return 'Добрый вечер';
    return 'Доброй ночи';
  }

  DailyTargets get _effectiveTargets =>
      AppStore.instance.dailyTargets ?? DailyTargets.defaultTargets;

  double _targetCaloriesFor(String mealType) {
    final plan = AppStore.instance.currentMealPlan;
    final today = DateTime.now();
    final todayDay = plan?.days.firstWhere(
      (d) =>
          d.date.year == today.year &&
          d.date.month == today.month &&
          d.date.day == today.day,
      orElse: () => plan.days.first,
    );
    final targets =
        AppStore.instance.dailyTargets ?? DailyTargets.defaultTargets;
    GeneratedMealRecipe? recipe;
    if (todayDay != null) {
      recipe = switch (mealType) {
        'breakfast' => todayDay.breakfast,
        'lunch' => todayDay.lunch,
        'snack' => todayDay.snack,
        'dinner' => todayDay.dinner,
        _ => null,
      };
    }
    if (recipe != null) return recipe.calories;

    return switch (mealType) {
      'breakfast' => targets.calories * 0.30,
      'lunch' => targets.calories * 0.35,
      'snack' => targets.calories * 0.10,
      'dinner' => targets.calories * 0.25,
      _ => 0,
    };
  }

  GeneratedMealRecipe? _planRecipeFor(String mealType) {
    final plan = AppStore.instance.currentMealPlan;
    if (plan == null) return null;
    final today = DateTime.now();
    try {
      final day = plan.days.firstWhere(
        (d) =>
            d.date.year == today.year &&
            d.date.month == today.month &&
            d.date.day == today.day,
      );
      return switch (mealType) {
        'breakfast' => day.breakfast,
        'lunch' => day.lunch,
        'snack' => day.snack,
        'dinner' => day.dinner,
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  void _showAddEntry(String mealType, String mealLabel) {
    final cs = Theme.of(context).colorScheme;
    final recipe = _planRecipeFor(mealType);

    final entries = AppStore.instance.todayDiary?.forMealType(mealType) ?? [];
    final planAlreadyLogged =
        recipe != null && entries.any((e) => e.recipeId == recipe.id);

    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fridgeSearchCtrl = TextEditingController();
    bool sending = false;
    String? mode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> submit({
            String? name,
            int? recipeId,
            required double cal,
            required double pro,
            required double fat,
            required double carb,
          }) async {
            if (sending) return;
            setSheet(() => sending = true);
            try {
              final today = DateTime.now().toIso8601String().substring(0, 10);
              await DiaryService.instance.addEntry(
                date: today,
                mealType: mealType,
                name: name,
                recipeId: recipeId,
                calories: cal,
                proteins: pro,
                fats: fat,
                carbs: carb,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              await _reload();
            } catch (_) {
              setSheet(() => sending = false);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cs.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    mealLabel,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (recipe != null && !planAlreadyLogged) ...[
                    _addOptionTile(
                      cs,
                      icon: Icons.check_circle_outline,
                      title: 'Съел по рациону',
                      subtitle:
                          '${recipe.name} · ${recipe.calories.toStringAsFixed(0)} ккал',
                      onTap: sending
                          ? null
                          : () => submit(
                              name: recipe.name,
                              recipeId: recipe.id,
                              cal: recipe.calories,
                              pro: recipe.proteins,
                              fat: recipe.fats,
                              carb: recipe.carbs,
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (mode == null) ...[
                    if (AppStore.instance.fridgeItems.isNotEmpty)
                      _addOptionTile(
                        cs,
                        icon: Icons.kitchen_outlined,
                        title: 'Из холодильника',
                        subtitle: 'Выбрать продукт из вашего холодильника',
                        onTap: () => setSheet(() => mode = 'fridge'),
                      ),
                    const SizedBox(height: 8),
                    _addOptionTile(
                      cs,
                      icon: Icons.edit_outlined,
                      title: 'Добавить своё',
                      subtitle: 'Ввести название и КБЖУ вручную',
                      onTap: () => setSheet(() => mode = 'custom'),
                    ),
                  ],
                  if (mode == 'fridge') ...[
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setSheet(() {
                            mode = null;
                            fridgeSearchCtrl.clear();
                          }),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 16,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Из холодильника',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.outline.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Icon(
                            Icons.search,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: fridgeSearchCtrl,
                              autofocus: true,
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Начните вводить название...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setSheet(() {}),
                            ),
                          ),
                          if (fridgeSearchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                fridgeSearchCtrl.clear();
                                setSheet(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Builder(
                      builder: (bCtx) {
                        final q = fridgeSearchCtrl.text.toLowerCase().trim();
                        final filtered = AppStore.instance.fridgeItems
                            .where(
                              (it) =>
                                  q.isEmpty ||
                                  it.productName.toLowerCase().contains(q),
                            )
                            .toList();
                        if (filtered.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Ничего не найдено',
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: filtered.length,
                            separatorBuilder: (_, s) => Divider(
                              height: 0,
                              color: cs.outline.withValues(alpha: 0.2),
                            ),
                            itemBuilder: (_, i) {
                              final item = filtered[i];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  item.productName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurface,
                                  ),
                                ),
                                trailing: item.calories > 0
                                    ? Text(
                                        '${item.calories.toStringAsFixed(0)} ккал',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      )
                                    : null,
                                onTap: () => submit(
                                  name: item.productName,
                                  cal: item.calories,
                                  pro: item.proteins,
                                  fat: item.fats,
                                  carb: item.carbs,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                  if (mode == 'custom') ...[
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setSheet(() => mode = null),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 16,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Добавить своё',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _inputField(cs, nameCtrl, 'Название', 'Банан'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _inputField(
                            cs,
                            calCtrl,
                            'Ккал',
                            '89',
                            numeric: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _inputField(
                            cs,
                            proCtrl,
                            'Белки, г',
                            '1.1',
                            numeric: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _inputField(
                            cs,
                            fatCtrl,
                            'Жиры, г',
                            '0.3',
                            numeric: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _inputField(
                            cs,
                            carbCtrl,
                            'Углев., г',
                            '23',
                            numeric: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: sending
                            ? null
                            : () {
                                final name = nameCtrl.text.trim();
                                if (name.isEmpty) return;
                                submit(
                                  name: name,
                                  cal: double.tryParse(calCtrl.text) ?? 0,
                                  pro: double.tryParse(proCtrl.text) ?? 0,
                                  fat: double.tryParse(fatCtrl.text) ?? 0,
                                  carb: double.tryParse(carbCtrl.text) ?? 0,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Добавить',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _addOptionTile(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    ColorScheme cs,
    TextEditingController ctrl,
    String label,
    String hint, {
    bool numeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        const SizedBox(height: 3),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: cs.outline.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: numeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: numeric
                ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
                : null,
            style: TextStyle(fontSize: 13, color: cs.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final greeting = _userName.isEmpty ? _greeting : '$_greeting, $_userName!';
    final targets = _effectiveTargets;
    final diary = AppStore.instance.todayDiary;
    final totals = diary?.totals ?? DiaryTotals.empty;

    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDiary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _header(cs, greeting),
                  const SizedBox(height: 16),
                  _mealPlanBanner(context, cs),
                  const SizedBox(height: 20),
                  _summaryCard(cs, targets, totals),
                  const SizedBox(height: 24),
                  Text(
                    'Сегодня вы съели',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._mealTypes.map((t) {
                    final (type, emoji, label) = t;
                    final entries = diary?.forMealType(type) ?? [];
                    final eaten = entries.fold(0.0, (s, e) => s + e.calories);
                    final target = _targetCaloriesFor(type);
                    return _mealSlot(
                      cs,
                      type,
                      emoji,
                      label,
                      eaten,
                      target,
                      entries,
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _header(ColorScheme cs, String greeting) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          greeting,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ),
      Icon(Icons.notifications_outlined, color: cs.onSurface),
    ],
  );

  Widget _mealPlanBanner(BuildContext context, ColorScheme cs) {
    final plan = AppStore.instance.currentMealPlan;
    return GestureDetector(
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MealPlanScreen()));
        if (mounted) setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.restaurant_menu_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan != null ? plan.name : 'Мой рацион',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    plan != null
                        ? '≈ ${plan.avgDailyCalories.toStringAsFixed(0)} ккал/день · ${plan.days.length} дн.'
                        : 'Создайте персональный рацион',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    ColorScheme cs,
    DailyTargets targets,
    DiaryTotals totals,
  ) {
    final progress = (totals.calories / targets.calories).clamp(0.0, 1.0);
    final eaten = totals.calories.toStringAsFixed(0);
    final target = targets.calories.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сводка за день',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: eaten,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                TextSpan(
                  text: ' / $target ккал',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: cs.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _macroCell(
                cs,
                'Углеводы',
                totals.carbs,
                targets.carbs,
                const Color(0xFF6C9EFF),
              ),
              _macroDivider(cs),
              _macroCell(
                cs,
                'Белки',
                totals.proteins,
                targets.proteins,
                const Color(0xFF4CAF50),
              ),
              _macroDivider(cs),
              _macroCell(
                cs,
                'Жиры',
                totals.fats,
                targets.fats,
                const Color(0xFFFF9800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroCell(
    ColorScheme cs,
    String label,
    double eaten,
    double target,
    Color color,
  ) {
    String fmt(double v) =>
        v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: fmt(eaten),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: ' / ${fmt(target)} г',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroDivider(ColorScheme cs) =>
      Container(width: 1, height: 28, color: cs.outline.withValues(alpha: 0.3));

  Widget _mealSlot(
    ColorScheme cs,
    String type,
    String emoji,
    String label,
    double eaten,
    double target,
    List<DiaryEntry> entries,
  ) {
    String fmt(double v) => v.toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.outline.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        '${fmt(eaten)} / ${fmt(target)} ккал',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAddEntry(type, label),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: cs.primary, size: 20),
                  ),
                ),
              ],
            ),
          ),
          if (entries.isNotEmpty) ...[
            Divider(height: 0, color: cs.outline.withValues(alpha: 0.3)),
            ...entries.map((e) => _entryRow(cs, e)),
          ],
        ],
      ),
    );
  }

  Widget _entryRow(ColorScheme cs, DiaryEntry entry) {
    return Dismissible(
      key: Key('diary_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) async {
        try {
          await DiaryService.instance.deleteEntry(entry.id);
          await _reload();
        } catch (_) {}
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(70, 8, 14, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.name,
                style: TextStyle(fontSize: 13, color: cs.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${entry.calories.toStringAsFixed(0)} ккал',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
