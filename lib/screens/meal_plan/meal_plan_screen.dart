import 'package:flutter/material.dart';
import '../../models/generated_meal_plan.dart';
import '../../services/diary_service.dart';
import '../../services/meal_plan_service.dart';
import '../../store.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  bool _generating = false;
  bool _loadingLocal = true;
  String? _errorMessage;

  GeneratedMealPlan? get _plan => AppStore.instance.currentMealPlan;

  @override
  void initState() {
    super.initState();
    _restorePlan();
  }

  Future<void> _restorePlan() async {
    if (AppStore.instance.currentMealPlan == null) {
      final saved = await MealPlanService.instance.loadPlanLocally();
      if (mounted && saved != null) {
        AppStore.instance.currentMealPlan = saved;
      }
    }
    if (mounted) setState(() => _loadingLocal = false);
  }

  Future<void> _generate(int days) async {
    setState(() {
      _generating = true;
      _errorMessage = null;
    });
    try {
      final plan = await MealPlanService.instance.generatePlan(days);
      if (!mounted) return;
      AppStore.instance.currentMealPlan = plan;

      final diary = AppStore.instance.todayDiary;
      if (diary != null && diary.entries.isNotEmpty) {
        for (final entry in diary.entries) {
          DiaryService.instance.deleteEntry(entry.id).catchError((_) {});
        }
        AppStore.instance.todayDiary = null;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('профиль')
              ? 'Заполните профиль: вес, активность, цель'
              : 'Не удалось создать рацион. Попробуйте снова.';
        });
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _showDaysPicker() {
    int selected = 7;
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                decoration: BoxDecoration(
                  color: cs.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'На сколько дней?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                children: List.generate(7, (i) {
                  final days = i + 1;
                  final sel = selected == days;
                  return GestureDetector(
                    onTap: () => setSheet(() => selected = days),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: sel
                            ? cs.primary
                            : cs.outline.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$days',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _generate(selected);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Сгенерировать',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          'Мой рацион',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_plan != null)
            IconButton(
              icon: Icon(Icons.refresh, color: cs.onSurface),
              tooltip: 'Пересоставить',
              onPressed: _generating ? null : _showDaysPicker,
            ),
        ],
      ),
      body: _loadingLocal
          ? const Center(child: CircularProgressIndicator())
          : _generating
          ? _buildLoading(cs)
          : _plan == null
          ? _buildEmpty(cs)
          : _buildPlan(cs),
    );
  }

  Widget _buildLoading(ColorScheme cs) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: cs.primary),
        const SizedBox(height: 16),
        Text(
          'Составляем рацион…',
          style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
        ),
      ],
    ),
  );

  Widget _buildEmpty(ColorScheme cs) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu_outlined, size: 72, color: cs.outline),
          const SizedBox(height: 20),
          Text(
            'Рацион не создан',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Мы подберём рецепты на основе\nвашего профиля и предпочтений',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.red),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _showDaysPicker,
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'Создать рацион',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildPlan(ColorScheme cs) {
    final plan = _plan!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        _planHeader(cs, plan),
        const SizedBox(height: 16),
        ...plan.days.map((d) => _dayCard(cs, d)),
      ],
    );
  }

  Widget _planHeader(ColorScheme cs, GeneratedMealPlan plan) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${fmt(plan.startDate)} — ${fmt(plan.endDate)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '≈ ${plan.avgDailyCalories.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'ккал/день',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayCard(ColorScheme cs, GeneratedMealDay day) {
    const weekdays = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    final name = weekdays[day.date.weekday - 1];
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
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                Text(
                  '${day.totalCalories.toStringAsFixed(0)} ккал',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 0, color: cs.outline.withValues(alpha: 0.4)),
          _mealRow(cs, '🍳', 'Завтрак', day.breakfast),
          _mealRow(cs, '🥗', 'Обед', day.lunch),
          _mealRow(cs, '🍎', 'Перекус', day.snack),
          _mealRow(cs, '🌙', 'Ужин', day.dinner, last: true),
        ],
      ),
    );
  }

  Widget _mealRow(
    ColorScheme cs,
    String emoji,
    String label,
    GeneratedMealRecipe? recipe, {
    bool last = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              SizedBox(
                width: 68,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: recipe == null
                    ? Text(
                        '—',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${recipe.calories.toStringAsFixed(0)} ккал · ${recipe.cookTimeLabel}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
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
