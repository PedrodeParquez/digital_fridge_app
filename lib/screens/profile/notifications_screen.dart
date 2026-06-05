import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
  ];

  bool _masterEnabled = true;
  bool _expiryWarnings = true;
  bool _mealPlanReminders = true;
  bool _shoppingReminders = false;

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
          'Уведомления',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _masterTile(cs),
            if (_masterEnabled) ...[
              const SizedBox(height: 24),
              Text(
                'Типы уведомлений',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              _notifGroup(cs, [
                _NotifSetting(
                  icon: Icons.warning_amber_outlined,
                  iconColor: Colors.orange,
                  title: 'Срок годности',
                  subtitle: 'За 3 дня до истечения',
                  value: _expiryWarnings,
                  onChanged: (v) => setState(() => _expiryWarnings = v),
                ),
                _NotifSetting(
                  icon: Icons.calendar_month_outlined,
                  iconColor: const Color(0xFF2E9B45),
                  title: 'Планы питания',
                  subtitle: 'Напоминание о приёме пищи',
                  value: _mealPlanReminders,
                  onChanged: (v) => setState(() => _mealPlanReminders = v),
                ),
                _NotifSetting(
                  icon: Icons.shopping_cart_outlined,
                  iconColor: Colors.blue,
                  title: 'Список покупок',
                  subtitle: 'Напоминание о покупке продуктов',
                  value: _shoppingReminders,
                  onChanged: (v) => setState(() => _shoppingReminders = v),
                ),
              ]),
            ],
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: cs.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Уведомлений пока нет',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Здесь будут появляться уведомления\nоб истечении сроков годности и планах',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _masterTile(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _shadow,
      ),
      child: SwitchListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (_masterEnabled ? cs.primary : cs.outline).withValues(
              alpha: 0.15,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _masterEnabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: _masterEnabled ? cs.primary : cs.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Text(
          'Все уведомления',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        subtitle: Text(
          _masterEnabled ? 'Включены' : 'Выключены',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        value: _masterEnabled,
        onChanged: (v) => setState(() => _masterEnabled = v),
        activeThumbColor: cs.primary,
      ),
    );
  }

  Widget _notifGroup(ColorScheme cs, List<_NotifSetting> items) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _shadow,
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              SwitchListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: e.key == 0
                        ? const Radius.circular(16)
                        : Radius.zero,
                    topRight: e.key == 0
                        ? const Radius.circular(16)
                        : Radius.zero,
                    bottomLeft: isLast
                        ? const Radius.circular(16)
                        : Radius.zero,
                    bottomRight: isLast
                        ? const Radius.circular(16)
                        : Radius.zero,
                  ),
                ),
                secondary: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 18),
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                value: item.value,
                onChanged: item.onChanged,
                activeThumbColor: cs.primary,
              ),
              if (!isLast) Divider(height: 0, color: cs.outline, indent: 68),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _NotifSetting {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _NotifSetting({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
}
