// main.dart
import 'package:diapce_aplicationn/view/main_login.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainLogin(), // MainLogin ahora tiene su propio Scaffold
    );
  }
}