import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const DigitalFridgeApp());
}

class DigitalFridgeApp extends StatelessWidget {
  const DigitalFridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digital Fridge',
      theme: lightTheme,
      home: const LoginScreen(),
    );
  }
}
