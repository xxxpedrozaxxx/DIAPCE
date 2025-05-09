  import 'package:diapce_aplicationn/view/graph_view.dart';
  import 'package:diapce_aplicationn/view/hall.dart';
  import 'package:flutter/material.dart';

  class view extends StatelessWidget {
    const view({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Color(0xFFECF0F1), // Fondo gris claro
        appBar: AppBar(
          backgroundColor: Color(0xFF2C3E50), // Azul oscuro
          title: const Text(
            'DIAPCE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Nombre del proyecto',
                    style: TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField('Cantidad de cemento (kg.)'),
                _buildTextField('Cantidad de agua (L.)'),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Agregado')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField('Cantidad (kg.)')),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField('Aditivos'),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Aditivos Líquidos')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField('Cantidad (L.)')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Aditivos Sólidos')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField('Cantidad (kg.)')),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton('Cerrar', Colors.orange, () {Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Hall()),
      );}),
                    _buildButton('Descargar', Color(0xFF27AE60), () {}),
                    // Dentro del Row de botones:
  _buildButton('Graficar', Color(0xFF27AE60), () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const GraphView()),
    );
  }),
                  ],
                )
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildTextField(String label) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextField(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Color(0xFF2C3E50)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFBDC3C7)), // Borde gris medio
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2C3E50)), // Azul oscuro
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      );
    }

    Widget _buildButton(String text, Color color, VoidCallback onPressed) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      );
    }
  }
