import 'package:flutter/material.dart';

const _green = Color(0xFF2E9B45);

final lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  dividerColor: const Color(0xFFE0E0E0),
  colorScheme: const ColorScheme.light(
    primary: _green,
    surface: Colors.white,
    onSurface: Color(0xFF1A1A1A),
    onSurfaceVariant: Color(0xFF6C6C70),
    outline: Color(0xFFE0E0E0),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: _green,
    unselectedItemColor: Color(0xFF6C6C70),
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: TextStyle(fontSize: 11),
    unselectedLabelStyle: TextStyle(fontSize: 11),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: _green,
    foregroundColor: Colors.white,
    shape: CircleBorder(),
  ),
  inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none),
);
