import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/recipe.dart';
import '../../services/api_client.dart';
import '../../services/recipe_service.dart';
import '../main_scaffold.dart';

class _ListItem {
  final String key;
  final String label;
  final String? imageUrl;
  const _ListItem(this.key, this.label, [this.imageUrl]);
}

class OnboardingScreen extends StatefulWidget {
  final String? userName;
  final int? age;
  final double? weight;
  final double? height;
  final String? gender;

  const OnboardingScreen({
    super.key,
    this.userName,
    this.age,
    this.weight,
    this.height,
    this.gender,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  String? _selectedGoal;
  String? _selectedActivity;

  final Set<String> _selectedAvoid = {};
  final Set<String> _selectedAppliances = {};
  final Set<String> _selectedDishes = {};
  final Set<String> _selectedFavProducts = {};

  List<Recipe> _recipes = [];
  bool _loadingRecipes = true;
  bool _recipesError = false;

  List<_ListItem> _avoidItems = [];
  List<_ListItem> _applianceItems = [];
  List<_ListItem> _favProductItems = [];
  bool _loadingOptions = true;

  static const _totalPages = 5;
  bool _showHint = false;
  bool _saving = false;

  static String _mapGoal(String label) => switch (label) {
    'Похудеть' => 'weight_loss',
    'Набрать вес' => 'muscle_gain',
    _ => 'maintenance',
  };

  static String _mapActivity(String label) => switch (label) {
    'Высокая' => 'very_active',
    'Умеренная' => 'moderately_active',
    _ => 'sedentary',
  };

  @override
  void initState() {
    super.initState();
    final dio = ApiClient.instance.dio;

    RecipeService.instance
        .getRecipes()
        .then((recipes) {
          final seen = <String>{};
          final unique = recipes.where((r) => seen.add(r.id)).toList();
          if (mounted)
            setState(() {
              _recipes = unique;
              _loadingRecipes = false;
              _recipesError = false;
            });
        })
        .catchError((_) {
          if (mounted)
            setState(() {
              _loadingRecipes = false;
              _recipesError = true;
            });
        });

    dio
        .get('/preferences/options')
        .then((res) {
          final data = res.data as Map<String, dynamic>;
          _ListItem parseOption(Map<String, dynamic> e) => _ListItem(
            e['key'] as String,
            e['label'] as String,
            e['image_url'] as String?,
          );
          if (mounted) {
            setState(() {
              _avoidItems = (data['intolerances'] as List)
                  .map((e) => parseOption(e as Map<String, dynamic>))
                  .toList();
              _applianceItems = (data['kitchen_equipment'] as List)
                  .map((e) => parseOption(e as Map<String, dynamic>))
                  .toList();
              _favProductItems = (data['favorite_products'] as List)
                  .map((e) => parseOption(e as Map<String, dynamic>))
                  .toList();
              _loadingOptions = false;
            });
          }
        })
        .catchError((_) {
          if (mounted) setState(() => _loadingOptions = false);
        });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _selectedGoal != null && _selectedActivity != null;
      case 1:
        return true;
      case 2:
        return _selectedAppliances.isNotEmpty;
      case 3:
        return _selectedFavProducts.isNotEmpty;
      case 4:
        return _selectedDishes.isNotEmpty || _suggestedRecipes.isEmpty;
      default:
        return true;
    }
  }

  String? _hintText() {
    switch (_currentPage) {
      case 0:
        if (_selectedGoal == null) return 'Выберите вашу цель';
        if (_selectedActivity == null) return 'Выберите уровень активности';
        return null;
      case 2:
        return 'Выберите хотя бы одну технику';
      case 3:
        return 'Выберите хотя бы один продукт';
      case 4:
        return 'Выберите хотя бы одно блюдо';
      default:
        return null;
    }
  }

  void _next() async {
    if (!_canProceed()) {
      setState(() => _showHint = true);
      return;
    }
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      await _finish(savePrefs: true);
    }
  }

  Future<void> _finish({bool savePrefs = false}) async {
    if (savePrefs) {
      setState(() => _saving = true);

      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('access_token') ?? '';
      final options = Options(headers: {'Authorization': 'Bearer $token'});
      final dio = ApiClient.instance.dio;

      try {
        await Future.wait([
          dio.put(
            '/profile',
            data: {
              if (widget.age != null && widget.age! > 0) 'age': widget.age,
              if (widget.gender != null) 'gender': widget.gender,
              if (widget.weight != null && widget.weight! > 0)
                'weight': widget.weight,
              if (widget.height != null && widget.height! > 0)
                'height': widget.height,
              if (_selectedActivity != null)
                'activity_level': _mapActivity(_selectedActivity!),
            },
            options: options,
          ),
          dio.put(
            '/profile/preferences',
            data: {
              if (_selectedGoal != null) 'goal': _mapGoal(_selectedGoal!),
              'intolerances': _selectedAvoid.toList(),
              'favorite_products': _selectedFavProducts.toList(),
              'favorite_cuisines': _selectedDishes.toList(),
              'kitchen_equipment': _selectedAppliances.toList(),
            },
            options: options,
          ),
        ]);
      } catch (_) {}

      if (mounted) setState(() => _saving = false);
    }

    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScaffold()),
      );
    }
  }

  void _toggle(Set<String> set, String value) {
    setState(() {
      set.contains(value) ? set.remove(value) : set.add(value);
      _showHint = false;
    });
  }

  int _favScore(Recipe r, List<String> favProducts) {
    final text = r.ingredients
        .map((i) => i.productName.toLowerCase())
        .join(' ');
    return favProducts.where((p) => text.contains(p)).length;
  }

  List<Recipe> get _suggestedRecipes {
    final avoid = _selectedAvoid.map((k) => k.toLowerCase()).toSet();
    var filtered = _recipes.where((r) {
      if (avoid.isEmpty) return true;
      final text = r.ingredients
          .map((i) => i.productName.toLowerCase())
          .join(' ');
      return !avoid.any((key) => text.contains(key));
    }).toList();

    if (filtered.isEmpty && _recipes.isNotEmpty) filtered = List.of(_recipes);
    final favProducts = _selectedFavProducts
        .map((k) => k.toLowerCase())
        .toList();
    if (favProducts.isNotEmpty) {
      filtered.sort(
        (a, b) => _favScore(b, favProducts) - _favScore(a, favProducts),
      );
    }
    if (filtered.length > 10) filtered = filtered.sublist(0, 10);
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLast = _currentPage == _totalPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _topBar(cs),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() {
                  _currentPage = i;
                  _showHint = false;
                }),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _GoalPage(
                    selectedGoal: _selectedGoal,
                    selectedActivity: _selectedActivity,
                    onGoalSelect: (v) => setState(() {
                      _selectedGoal = v;
                      _showHint = false;
                    }),
                    onActivitySelect: (v) => setState(() {
                      _selectedActivity = v;
                      _showHint = false;
                    }),
                  ),
                  _ListPage(
                    title: 'Какие продукты Вы\nхотели бы избегать?',
                    subtitle:
                        'Выберите продукты, которые не хотите видеть в рецептах и рекомендациях.',
                    items: _avoidItems,
                    loading: _loadingOptions,
                    selected: _selectedAvoid,
                    onToggle: (v) => _toggle(_selectedAvoid, v),
                  ),
                  _ListPage(
                    title: 'Что из кухонной\nтехники у Вас есть?',
                    subtitle: 'Выберите технику, которая есть на Вашей кухне.',
                    items: _applianceItems,
                    loading: _loadingOptions,
                    selected: _selectedAppliances,
                    onToggle: (v) => _toggle(_selectedAppliances, v),
                  ),
                  _ListPage(
                    title: 'Какие продукты\nВы любите?',
                    subtitle:
                        'Это поможет нам подобрать подходящие рецепты для Вас.',
                    items: _favProductItems,
                    loading: _loadingOptions,
                    selected: _selectedFavProducts,
                    onToggle: (v) => _toggle(_selectedFavProducts, v),
                  ),
                  _DishPage(
                    title: 'Какие блюда Вам\nпонравились?',
                    subtitle: 'Выберите блюда, которые Вам понравились.',
                    recipes: _suggestedRecipes,
                    loading: _loadingRecipes,
                    error: _recipesError,
                    onRetry: () {
                      setState(() {
                        _loadingRecipes = true;
                        _recipesError = false;
                      });
                      RecipeService.instance
                          .getRecipes()
                          .then((recipes) {
                            final seen = <String>{};
                            final unique = recipes
                                .where((r) => seen.add(r.id))
                                .toList();
                            if (mounted)
                              setState(() {
                                _recipes = unique;
                                _loadingRecipes = false;
                              });
                          })
                          .catchError((_) {
                            if (mounted)
                              setState(() {
                                _loadingRecipes = false;
                                _recipesError = true;
                              });
                          });
                    },
                    selected: _selectedDishes,
                    onToggle: (v) => _toggle(_selectedDishes, v),
                  ),
                ],
              ),
            ),
            _bottomButton(cs, isLast),
          ],
        ),
      ),
    );
  }

  Widget _topBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => _finish(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Пропустить',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_totalPages, (i) {
              final active = i <= _currentPage;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  margin: EdgeInsets.only(right: i < _totalPages - 1 ? 5 : 0),
                  decoration: BoxDecoration(
                    color: active ? cs.primary : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _bottomButton(ColorScheme cs, bool isLast) {
    final canProceed = _canProceed();
    final hint = _hintText();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          AnimatedOpacity(
            opacity: _showHint && hint != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                hint ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (canProceed && !_saving) ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canProceed
                    ? cs.primary
                    : cs.primary.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                disabledBackgroundColor: cs.primary.withValues(alpha: 0.35),
                disabledForegroundColor: Colors.white,
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
                  : Text(
                      isLast ? 'Начать' : 'Далее',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  final String? selectedGoal;
  final String? selectedActivity;
  final void Function(String) onGoalSelect;
  final void Function(String) onActivitySelect;

  const _GoalPage({
    required this.selectedGoal,
    required this.selectedActivity,
    required this.onGoalSelect,
    required this.onActivitySelect,
  });

  static const _goals = [
    (
      label: 'Похудеть',
      subtitle: 'Снизить массу тела',
      icon: Icons.trending_down,
    ),
    (
      label: 'Поддерживать вес',
      subtitle: 'Сохранить текущую форму',
      icon: Icons.balance,
    ),
    (
      label: 'Набрать вес',
      subtitle: 'Увеличить мышечную массу',
      icon: Icons.trending_up,
    ),
  ];

  static const _activities = [
    (label: 'Минимальная', subtitle: 'Сидячий образ жизни'),
    (label: 'Умеренная', subtitle: '1–3 тренировки в неделю'),
    (label: 'Высокая', subtitle: '4–5 тренировок в неделю'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Расскажите\nо своих целях',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Это поможет нам рассчитать оптимальный рацион.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Text(
            'Ваша цель',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ..._goals.map((g) => _goalCard(cs, g.label, g.subtitle, g.icon)),
          const SizedBox(height: 20),
          Text(
            'Уровень активности',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ..._activities.map((a) => _activityCard(cs, a.label, a.subtitle)),
        ],
      ),
    );
  }

  Widget _goalCard(
    ColorScheme cs,
    String label,
    String subtitle,
    IconData icon,
  ) {
    final selected = selectedGoal == label;
    return GestureDetector(
      onTap: () => onGoalSelect(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.08) : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cs.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? cs.primary.withValues(alpha: 0.15)
                    : cs.outline.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? cs.primary : cs.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? cs.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? cs.primary : cs.outline,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityCard(ColorScheme cs, String label, String subtitle) {
    final selected = selectedActivity == label;
    return GestureDetector(
      onTap: () => onActivitySelect(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.08) : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? cs.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? cs.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? cs.primary : cs.outline,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool selected;
  const _Checkbox(this.selected);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? cs.primary : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    );
  }
}

class _ListPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_ListItem> items;
  final bool loading;
  final Set<String> selected;
  final void Function(String) onToggle;

  const _ListPage({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.loading,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseUrl = ApiClient.baseUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final isSelected = selected.contains(item.key);
                    return GestureDetector(
                      onTap: () => onToggle(item.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primary.withValues(alpha: 0.06)
                              : cs.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? cs.primary.withValues(alpha: 0.4)
                                : Colors.transparent,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0C000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: item.imageUrl != null
                                  ? Image.network(
                                      '$baseUrl${item.imageUrl}',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          _imgPlaceholder(cs),
                                    )
                                  : _imgPlaceholder(cs),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            _Checkbox(isSelected),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _imgPlaceholder(ColorScheme cs) => Container(
    width: 48,
    height: 48,
    color: cs.outline.withValues(alpha: 0.3),
  );
}

class _DishPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Recipe> recipes;
  final bool loading;
  final bool error;
  final VoidCallback onRetry;
  final Set<String> selected;
  final void Function(String) onToggle;

  const _DishPage({
    required this.title,
    required this.subtitle,
    required this.recipes,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : (error || recipes.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          error
                              ? Icons.wifi_off_outlined
                              : Icons.restaurant_menu_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          error
                              ? 'Не удалось загрузить рецепты'
                              : 'Рецепты не найдены',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (error) ...[
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: onRetry,
                            child: const Text('Повторить'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: recipes.length,
                  itemBuilder: (context, i) {
                    final recipe = recipes[i];
                    final isSelected = selected.contains(recipe.name);
                    return GestureDetector(
                      onTap: () => onToggle(recipe.name),
                      child: _DishCard(
                        name: recipe.name,
                        imageUrl: recipe.mainImageUrl,
                        isSelected: isSelected,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DishCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool isSelected;
  const _DishCard({
    required this.name,
    this.imageUrl,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? cs.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl != null
                      ? Image.network(
                          '${ApiClient.baseUrl}$imageUrl',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _dishPlaceholder(cs),
                        )
                      : _dishPlaceholder(cs),
                  Positioned(top: 8, right: 8, child: _Checkbox(isSelected)),
                  if (isSelected)
                    Container(color: cs.primary.withValues(alpha: 0.15)),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: cs.surface,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dishPlaceholder(ColorScheme cs) => Container(
    color: cs.outline.withValues(alpha: 0.25),
    child: Icon(Icons.restaurant, color: cs.onSurfaceVariant, size: 36),
  );
}
