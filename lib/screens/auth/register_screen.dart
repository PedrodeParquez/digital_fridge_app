import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import 'onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _selectedGender;
  bool _loading = false;
  String? _error;

  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_nameController.text.trim().isEmpty) return 'Введите имя';
    if (_selectedGender == null) return 'Выберите пол';
    if (_ageController.text.isEmpty) return 'Введите возраст';
    if (_weightController.text.isEmpty) return 'Введите вес';
    if (_heightController.text.isEmpty) return 'Введите рост';
    final height = double.tryParse(_heightController.text);
    if (height == null || height < 100 || height > 250) {
      return 'Рост должен быть от 100 до 250 см';
    }
    if (_emailController.text.trim().isEmpty) return 'Введите email';
    if (_passwordController.text.length < 6) return 'Пароль минимум 6 символов';
    if (_passwordController.text != _confirmController.text) {
      return 'Пароли не совпадают';
    }
    return null;
  }

  Future<void> _register() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.instance.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OnboardingScreen(
            userName: _nameController.text.trim(),
            age: int.tryParse(_ageController.text),
            weight: double.tryParse(_weightController.text),
            height: double.tryParse(_heightController.text),
            gender: _selectedGender == 'Мужской' ? 'male' : 'female',
          ),
        ),
      );
    } catch (e) {
      if (mounted)
        setState(() => _error = 'Ошибка регистрации. Попробуйте снова.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                'Давайте\nпознакомимся',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Заполните данные, чтобы начать',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              _field(
                cs,
                controller: _nameController,
                label: 'Как вас зовут?',
                hint: 'Имя',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              _genderField(cs),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      cs,
                      controller: _ageController,
                      label: 'Возраст',
                      hint: '25',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      cs,
                      controller: _weightController,
                      label: 'Вес (кг)',
                      hint: '70',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      cs,
                      controller: _heightController,
                      label: 'Рост (см)',
                      hint: '175',
                      icon: Icons.height,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _field(
                cs,
                controller: _emailController,
                label: 'Введите email',
                hint: 'example@mail.ru',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _passwordField(
                cs,
                controller: _passwordController,
                label: 'Придумайте пароль',
                obscure: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 14),
              _passwordField(
                cs,
                controller: _confirmController,
                label: 'Повторите пароль',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: cs.primary.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Создать аккаунт',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Уже есть аккаунт? ',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Войти',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    ColorScheme cs, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _shadow,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(color: cs.onSurface, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: cs.onSurfaceVariant),
              prefixIcon: Icon(icon, color: cs.onSurfaceVariant, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderField(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Выберите ваш пол',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _genderChip(cs, 'Мужской', Icons.male),
            const SizedBox(width: 10),
            _genderChip(cs, 'Женский', Icons.female),
          ],
        ),
      ],
    );
  }

  Widget _genderChip(ColorScheme cs, String value, IconData icon) {
    final selected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedGender = value;
          _error = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? cs.primary.withValues(alpha: 0.1) : cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? cs.primary : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: _shadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? cs.primary : cs.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField(
    ColorScheme cs, {
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _shadow,
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(color: cs.onSurface, fontSize: 15),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: TextStyle(color: cs.onSurfaceVariant),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: cs.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: onToggle,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
