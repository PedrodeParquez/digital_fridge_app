import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/preference_option.dart';
import '../../models/user_preferences.dart';
import '../../services/meal_plan_service.dart';
import '../../services/preferences_service.dart';
import '../../services/user_service.dart';
import '../auth/onboarding_screen.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  UserPreferences? _prefs;
  PreferencesOptions? _options;
  String? _activityLevel;

  String _initialName = '';
  String _initialAge = '';
  String _initialWeight = '';
  String _initialHeight = '';

  bool get _hasChanges =>
      _nameController.text.trim() != _initialName ||
      _ageController.text != _initialAge ||
      _weightController.text != _initialWeight ||
      _heightController.text != _initialHeight;

  void _onFieldChanged() => setState(() {});

  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _ageController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) UserService.instance.clearCache();
      final profileFuture = UserService.instance.cached != null
          ? Future.value(UserService.instance.cached!)
          : UserService.instance.getProfile();
      final prefsFuture = PreferencesService.instance.getPreferences();

      final optionsFuture = PreferencesService.instance.getOptions();

      final profile = await profileFuture;
      _nameController.text = profile.name;
      _ageController.text = profile.age?.toString() ?? '';
      _weightController.text = profile.weight?.toString() ?? '';
      _heightController.text = profile.height?.toString() ?? '';
      _activityLevel = profile.activityLevel;
      _initialName = profile.name;
      _initialAge = profile.age?.toString() ?? '';
      _initialWeight = profile.weight?.toString() ?? '';
      _initialHeight = profile.height?.toString() ?? '';

      _prefs = await prefsFuture;
      _options = await optionsFuture;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final cached = UserService.instance.cached;
    if (cached == null) return;
    setState(() => _saving = true);
    try {
      final newAge = int.tryParse(_ageController.text);
      final newWeight = double.tryParse(_weightController.text);
      final newHeight = double.tryParse(_heightController.text);

      final updated = cached.copyWith(
        name: _nameController.text.trim(),
        age: newAge,
        weight: newWeight,
        height: newHeight,
      );
      await UserService.instance.updateProfile(updated);

      final tdeeChanged =
          newAge != cached.age ||
          newWeight != cached.weight ||
          newHeight != cached.height;
      if (tdeeChanged) {
        await MealPlanService.instance.clearPlanLocally();
      }

      if (mounted) {
        final msg = tdeeChanged
            ? 'Данные сохранены. Рацион сброшен — создайте новый.'
            : 'Данные сохранены.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFF2E9B45),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _labels(List<String> keys, List<PreferenceOption> options) {
    final map = {for (final o in options) o.key: o.label};
    return keys.map((k) => map[k] ?? k).toList();
  }

  static String _goalLabel(String? g) => switch (g) {
    'weight_loss' => 'Похудеть',
    'muscle_gain' => 'Набор массы',
    'maintenance' => 'Поддержание веса',
    _ => 'Не указана',
  };

  static String _activityLabel(String? a) => switch (a) {
    'sedentary' => 'Минимальная',
    'lightly_active' => 'Слабая',
    'moderately_active' => 'Умеренная',
    'very_active' => 'Высокая',
    'extra_active' => 'Экстремальная',
    _ => 'Не указана',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: cs.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Личные данные',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        actions: const [],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(cs, 'Личная информация'),
                  const SizedBox(height: 10),
                  _infoCard(cs),
                  const SizedBox(height: 24),
                  _sectionLabel(cs, 'Вкусовые предпочтения'),
                  const SizedBox(height: 4),
                  Text(
                    'Цель, активность, продукты и техника',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  _prefsCard(cs),
                  const SizedBox(height: 10),
                  _preferenceTile(cs),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_saving || !_hasChanges) ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: cs.primary.withValues(
                          alpha: 0.35,
                        ),
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
                          : const Text(
                              'Сохранить изменения',
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
    );
  }

  Widget _infoCard(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _shadow,
      ),
      child: Column(
        children: [
          _editRow(
            cs,
            label: 'Имя',
            controller: _nameController,
            hint: 'Введите имя',
            showDivider: true,
          ),
          _editRow(
            cs,
            label: 'Возраст',
            controller: _ageController,
            hint: '—',
            keyboard: TextInputType.number,
            showDivider: true,
          ),
          _editRow(
            cs,
            label: 'Вес (кг)',
            controller: _weightController,
            hint: '—',
            keyboard: TextInputType.number,
            showDivider: true,
          ),
          _editRow(
            cs,
            label: 'Рост (см)',
            controller: _heightController,
            hint: '—',
            keyboard: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _prefsCard(ColorScheme cs) {
    final prefs = _prefs;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _shadow,
      ),
      child: Column(
        children: [
          _prefRow(cs, 'Цель', _goalLabel(prefs?.goal), divider: true),
          _prefRow(
            cs,
            'Активность',
            _activityLabel(_activityLevel),
            divider: true,
          ),
          _prefRowChips(
            cs,
            'Избегаю',
            _labels(prefs?.intolerances ?? [], _options?.intolerances ?? []),
            divider: true,
          ),
          _prefRowChips(
            cs,
            'Люблю',
            _labels(
              prefs?.favoriteProducts ?? [],
              _options?.favoriteProducts ?? [],
            ),
            divider: true,
          ),
          _prefRowChips(
            cs,
            'Техника',
            _labels(
              prefs?.kitchenEquipment ?? [],
              _options?.kitchenEquipment ?? [],
            ),
          ),
        ],
      ),
    );
  }

  Widget _prefRow(
    ColorScheme cs,
    String label,
    String value, {
    bool divider = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (divider)
          Divider(height: 0, color: Theme.of(context).dividerColor, indent: 16),
      ],
    );
  }

  Widget _prefRowChips(
    ColorScheme cs,
    String label,
    List<String> items, {
    bool divider = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Text(
                        'Не указано',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.end,
                        children: items.map((s) => _chip(cs, s)).toList(),
                      ),
              ),
            ],
          ),
        ),
        if (divider)
          Divider(height: 0, color: Theme.of(context).dividerColor, indent: 16),
      ],
    );
  }

  Widget _chip(ColorScheme cs, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: cs.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: cs.primary,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _editRow(
    ColorScheme cs, {
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboard,
                  textAlign: TextAlign.right,
                  inputFormatters: keyboard == TextInputType.number
                      ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
                      : null,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 0, color: Theme.of(context).dividerColor, indent: 16),
      ],
    );
  }

  Widget _preferenceTile(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _shadow,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.tune, color: cs.primary, size: 20),
        ),
        title: Text(
          'Изменить предпочтения',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
        ),
        subtitle: Text(
          'Цель, активность, продукты, техника',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        onTap: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
          await MealPlanService.instance.clearPlanLocally();
          setState(() => _loading = true);
          await _loadProfile(forceRefresh: true);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _sectionLabel(ColorScheme cs, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: cs.onSurface,
      ),
    );
  }
}
