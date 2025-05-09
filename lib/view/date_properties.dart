import 'package:diapce_aplicationn/view/date_person.dart';
import 'package:diapce_aplicationn/view/view__properties.dart';
import 'package:flutter/material.dart';

class Properties extends StatelessWidget {
   final String projectName;

  const Properties({Key? key, required this.projectName, required Null Function() onSave}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Center(
                child: Text(
                  projectName,
                  style: const TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFFBDC3C7)),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        style: const TextStyle(color: Color(0xFF2C3E50)),
                        decoration: InputDecoration(
                          labelText: 'Nivel de resistencia (MPa.)',
                          labelStyle: const TextStyle(color: Color(0xFF2C3E50)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        style: const TextStyle(color: Color(0xFF2C3E50)),
                        decoration: InputDecoration(
                          labelText: 'Condiciones de temperatura (°C.)',
                          labelStyle: const TextStyle(color: Color(0xFF2C3E50)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        style: const TextStyle(color: Color(0xFF2C3E50)),
                        decoration: InputDecoration(
                          labelText: 'Condición de humedad (%)',
                          labelStyle: const TextStyle(color: Color(0xFF2C3E50)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Tipo de obra',
                          labelStyle: const TextStyle(color: Color(0xFF2C3E50)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Residencial', child: Text('Puentes')),
                          DropdownMenuItem(value: 'Comercial', child: Text('Tuneles')),
                          DropdownMenuItem(value: 'Industrial', child: Text('Muros de contención')),
                        ],
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Date()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE67E22),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Volver'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const view()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Crear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
