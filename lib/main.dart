// main.dart
import 'package:diapce_aplicationn/core/api_client.dart';
import 'package:diapce_aplicationn/core/theme/app_theme.dart';
import 'package:diapce_aplicationn/view/main_login.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Recupera el JWT guardado (si existe) para adjuntarlo a las peticiones.
  await ApiClient().loadToken();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DIAPCE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const MainLogin(),
    );
  }
}
