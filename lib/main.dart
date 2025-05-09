import 'package:diapce_aplicationn/components/add.dart';
import 'package:diapce_aplicationn/core/colors_app.dart';

import 'package:diapce_aplicationn/view/date_properties.dart';
import 'package:diapce_aplicationn/view/hall.dart';
import 'package:diapce_aplicationn/view/main_login.dart';
import 'package:diapce_aplicationn/view/view__properties.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        //backgroundColor: app_color.background,
        body: MainLogin()
        
      ),
    );
  }
}
