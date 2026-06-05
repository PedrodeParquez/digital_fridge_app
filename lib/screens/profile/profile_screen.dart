import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../auth/login_screen.dart';
import 'personal_data_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await UserService.instance.getProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = _profile?.name ?? '';
    final initials = _profile?.initials ?? '?';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Профиль',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _shadow,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: cs.primary.withValues(alpha: 0.15),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? '—' : name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        if (_profile?.email.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            _profile!.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Настройки',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _settingsTile(
              cs,
              icon: Icons.person_outline,
              title: 'Личные данные',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PersonalDataScreen()),
                );
                _loadProfile();
              },
            ),
            const SizedBox(height: 10),
            _settingsTile(
              cs,
              icon: Icons.notifications_outlined,
              title: 'Уведомления',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _settingsTile(
              cs,
              icon: Icons.logout,
              title: 'Выйти',
              iconColor: Colors.red.shade400,
              titleColor: Colors.red.shade400,
              showChevron: false,
              onTap: () async {
                final nav = Navigator.of(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Выйти из аккаунта?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Выйти',
                          style: TextStyle(color: Colors.red.shade400),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await AuthService.instance.logout();
                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
    bool showChevron = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _shadow,
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? cs.primary),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? cs.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: showChevron
            ? Icon(Icons.chevron_right, color: cs.onSurfaceVariant)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
