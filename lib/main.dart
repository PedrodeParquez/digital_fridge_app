import 'package:flutter/material.dart';

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
      home: Scaffold(
        body: Center(
          child: Text(
            'It is a Digital Fridge App',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.normal),
          ),
        ),
      ),
    );
  }
}
