import 'package:diapce_aplicationn/main.dart';

import 'package:diapce_aplicationn/view/date_person.dart';
import 'package:diapce_aplicationn/view/main_login.dart';
import 'package:flutter/material.dart';

class Hall extends StatefulWidget {
  const Hall({super.key});

  @override
  State<Hall> createState() => _HallState();
}

class _HallState extends State<Hall> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1), // Fondo gris claro
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF2C3E50), // Azul oscuro
              ),
              child: Center(
                child: Text(
                  'Menú',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.black, ),
              title: Text('Salir', style: TextStyle(fontSize: 20)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainApp()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50), // Azul oscuro
        elevation: 0,
        title: const Text(
          '                DIAPCE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        leadingWidth: 56,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(9.0),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blueGrey,
                    width: 2,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, size: 32, color: Colors.blueGrey),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Date()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
