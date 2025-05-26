// lib/view/create_project_screen.dart

import 'dart:io';
import 'package:diapce_aplicationn/core/project_data.dart';
import 'package:diapce_aplicationn/view/ViewExistingProjectScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  // Controladores de Date
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _creatorNameController = TextEditingController();
  DateTime? _selectedDate;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Controladores de Properties
  final TextEditingController _resistanceController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _humidityController = TextEditingController();
  String? _selectedWorkType;

  // GlobalKey para el Form
  final _formKey = GlobalKey<FormState>();


  @override
  void dispose() {
    _projectNameController.dispose();
    _creatorNameController.dispose();
    _resistanceController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
       builder: (context, child) { // Opcional: Estilo del DatePicker
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF27AE60), 
              onPrimary: Colors.white, 
            ),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _submitAndNavigateToDetails() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      // Si el formulario no es válido, no hacer nada más.
      // Los mensajes de error de los validadores se mostrarán.
      return;
    }
    if (_projectNameController.text.isEmpty) { // Doble chequeo, aunque el validator debería cubrirlo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa el nombre del proyecto.')),
      );
      return;
    }
    // Navega a ViewExistingProjectScreen con isNewProject=true y espera un resultado de tipo ProjectData
    final projectDataFromDetails = await Navigator.push<ProjectData>(
      context,
      MaterialPageRoute(
        builder: (context) => ViewExistingProjectScreen(
          project: ProjectData(
            projectName: _projectNameController.text,
            selectedDate: _selectedDate,
            selectedImage: _selectedImage,
            creatorName: _creatorNameController.text,
            resistanceLevel: _resistanceController.text,
            temperature: _temperatureController.text,
            humidity: _humidityController.text,
            workType: _selectedWorkType,
          ),
          isNewProject: true, // Indicamos que es un proyecto nuevo
        ),
      ),
    );

    // Si ViewExistingProjectScreen devolvió un ProjectData (porque se guardó),
    // entonces lo devolvemos a la pantalla anterior (Hall)
    if (projectDataFromDetails != null && mounted) {
      Navigator.pop(context, projectDataFromDetails);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      appBar: AppBar(
        title: const Text('Crear Nuevo Proyecto'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form( // Envolver en un Form para validación
          key: _formKey,
          child: Column(
            children: [
              _buildSectionContainer([ // Sección de Datos Generales
                const Text("Datos Generales", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _projectNameController,
                  decoration: _inputDecoration(labelText: 'Nombre del proyecto'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _pickDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _inputDecoration(
                        labelText: _selectedDate == null
                            ? 'Fecha'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        prefixIcon: Icons.calendar_today,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2, // Un poco más de espacio para el nombre del creador
                      child: TextFormField(
                        controller: _creatorNameController,
                        decoration: _inputDecoration(labelText: 'Nombre del creador'),
                         validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Imagen',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF2C3E50), fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 60, // Reducir un poco la altura para que quepa mejor
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBDC3C7)),
                              ),
                              child: _selectedImage == null
                                  ? const Icon(Icons.add_a_photo, size: 30, color: Color(0xFF2C3E50))
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                                    ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 20),
              _buildSectionContainer([ // Sección de Propiedades Técnicas
                const Text("Propiedades Técnicas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _resistanceController,
                  decoration: _inputDecoration(labelText: 'Nivel de resistencia (MPa.)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _temperatureController,
                  decoration: _inputDecoration(labelText: 'Condiciones de temperatura (°C.)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _humidityController,
                  decoration: _inputDecoration(labelText: 'Condición de humedad (%)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration(labelText: 'Tipo de obra'),
                  value: _selectedWorkType,
                  items: const [
                    DropdownMenuItem(value: 'Puentes', child: Text('Puentes')),
                    DropdownMenuItem(value: 'Tuneles', child: Text('Tuneles')),
                    DropdownMenuItem(value: 'Muros', child: Text('Muros de contención')),
                  ],
                  onChanged: (value) => setState(() => _selectedWorkType = value),
                  validator: (value) => value == null ? 'Campo requerido' : null,
                ),
              ]),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE67E22),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: const Text('Volver'),
                  ),
                  ElevatedButton(
                    onPressed: _submitAndNavigateToDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: const Text('Siguiente'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper para crear contenedores de sección
  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBDC3C7)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // Helper para la decoración de InputDecoration
  InputDecoration _inputDecoration({required String labelText, IconData? prefixIcon}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Color(0xFF2C3E50)),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF2C3E50)) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBDC3C7)),
      ),
      enabledBorder: OutlineInputBorder( // Borde cuando no está enfocado
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBDC3C7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF27AE60), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
    );
  }
}