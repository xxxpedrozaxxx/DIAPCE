import 'package:diapce_aplicationn/view/date_properties.dart';
import 'package:diapce_aplicationn/view/hall.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // <-- Importamos esto para seleccionar imágenes
import 'dart:io'; // Para manejar archivos locales

class Date extends StatefulWidget {
  const Date({super.key});

  @override
  State<Date> createState() => _DateState();
}

class _DateState extends State<Date> {
  DateTime? _selectedDate;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _projectNameController = TextEditingController();

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFFBDC3C7)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _projectNameController,  // <- agregas esto
                      decoration: InputDecoration(
                        labelText: 'Nombre del proyecto',
                        labelStyle: const TextStyle(color: Color(0xFF2C3E50)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFBDC3C7)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _pickDate(context),
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: _selectedDate == null
                                ? 'Fecha'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            labelStyle: const TextStyle(color: Color(0xFF2C3E50)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFBDC3C7)),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Imagen del proyecto',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _selectedImage == null
                                    ? Icon(Icons.image, size: 40, color: Color(0xFF2C3E50))
                                    : Image.file(
                                        _selectedImage!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Nombre del creador',
                              labelStyle: const TextStyle(color: Color(0xFF2C3E50)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFBDC3C7)),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const Hall()),
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
      MaterialPageRoute(
        builder: (context) => Properties(
          projectName: _projectNameController.text, onSave: () {  }, // <-- PASANDO EL NOMBRE
        ),
      ),
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
            ],
          ),
        ),
      ),
    );
  }
}
