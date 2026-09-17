  // main.dart
import 'dart:io' show Platform;

import 'package:diapce_aplicationn/core/database_helper.dart';
import 'package:diapce_aplicationn/view/main_login.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


// Cambiar a una inicialización más segura
DatabaseHelper get dbHelper => DatabaseHelper();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // En escritorio sqflite necesita el backend FFI antes de abrir la base de datos
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
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