import 'package:diapce_aplicationn/view/hall.dart';
import 'package:diapce_aplicationn/view/view__properties.dart';
import 'package:flutter/material.dart';

class GraphView extends StatelessWidget {
  const GraphView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECF0F1),
      appBar: AppBar(
        backgroundColor: Color(0xFF2C3E50),
        title: const Text(
          'Gráficas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const  view()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Resistencia megapascales',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Image.network(
              'https://portal.amelica.org/ameli/journal/595/5952727005/5952727005_gf3.png',
              height: 250,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Resistencia Humedad',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Image.network(
              'https://www.researchgate.net/publication/335582614/figure/fig2/AS:11431281114971958@1674734691367/Figura-9-Curvas-representativas-de-esfuerzo-MPa-versus-deformacion-unitaria-mm-mm.png',
              height: 250,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
