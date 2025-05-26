// main.dart
import 'package:diapce_aplicationn/core/database_helper.dart';
import 'package:diapce_aplicationn/view/main_login.dart';
import 'package:flutter/material.dart';


// Cambiar a una inicialización más segura
DatabaseHelper get dbHelper => DatabaseHelper();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar la base de datos al inicio
  await DatabaseHelper().database;
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