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
          children: [_masterTile(cs)],
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
          'Уведомления',
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
}
