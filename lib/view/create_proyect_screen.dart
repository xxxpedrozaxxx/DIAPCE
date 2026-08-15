// lib/view/create_project_screen.dart

import 'dart:io';
import 'package:diapce_aplicationn/models/project_data.dart';
import 'package:diapce_aplicationn/view/ViewExistingProjectScreen.dart';
import 'package:diapce_aplicationn/core/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CreateProjectScreen extends StatefulWidget {
  final int userId;
  const CreateProjectScreen({super.key, required this.userId});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  // Controladores de Date
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _creatorNameController = TextEditingController();
  final TextEditingController _resistanceController = TextEditingController();
  DateTime? _selectedDate;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Variables para el árbol de decisión
  double? _selectedResistanceTarget;
  int? _selectedTemperature;
  int? _selectedHumidity;
  double? _selectedRelacionAc;
  int? _selectedAditivoId;
  String? _selectedWorkType;

  // Opciones disponibles para los dropdowns
  List<int> _availableTemperatures = [10, 25, 32];
  List<int> _availableHumidities = [];
  List<double> _availableRelacionesAc = [];
  List<Map<String, dynamic>> _availableAditivos = [];

  // GlobalKey para el Form
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Cargar las opciones iniciales si es necesario
    // Por ahora las temperaturas están hardcodeadas
  }

  // Método para cargar opciones de humedad cuando se selecciona temperatura
  Future<void> _loadHumidityOptions(int temperatura) async {
    final db = DatabaseHelper();
    final humedades = await db.getOpcionesHumedad(temperatura);
    setState(() {
      _availableHumidities = humedades;
      _selectedHumidity = null;
      _availableRelacionesAc = [];
      _selectedRelacionAc = null;
      _availableAditivos = [];
      _selectedAditivoId = null;
    });
  }

  // Método para cargar opciones de relación a/c cuando se selecciona humedad
  Future<void> _loadRelacionAcOptions(int temperatura, int humedad) async {
    final db = DatabaseHelper();
    final relacionesAc = await db.getOpcionesRelacionAC(temperatura, humedad);
    setState(() {
      _availableRelacionesAc = relacionesAc;
      _selectedRelacionAc = null;
      _availableAditivos = [];
      _selectedAditivoId = null;
    });
  }

  // Método para cargar opciones de aditivos cuando se selecciona relación a/c
  Future<void> _loadAditivoOptions(int temperatura, int humedad, double relacionAc) async {
    final db = DatabaseHelper();
    final aditivos = await db.getAditivosConCodigos(temperatura, humedad, relacionAc);
    setState(() {
      _availableAditivos = aditivos;
      _selectedAditivoId = null;
    });
  }


  @override
  void dispose() {
    _projectNameController.dispose();
    _creatorNameController.dispose();
    _resistanceController.dispose();
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
      return;
    }
    if (_projectNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa el nombre del proyecto.')),
      );
      return;
    }
    if (_selectedResistanceTarget == null || _selectedTemperature == null || 
        _selectedHumidity == null || _selectedRelacionAc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todas las condiciones técnicas.')),
      );
      return;
    }

    // Calcular resistencias predichas basadas en los datos experimentales
    final db = DatabaseHelper();
    final resistencias = await db.getResistenciaPromedio(
      temperatura: _selectedTemperature!,
      humedad: _selectedHumidity!,
      relacionAc: _selectedRelacionAc!,
      aditivoId: _selectedAditivoId ?? 1, // Si no se seleccionó aditivo, usar el primero
    );

    // Navega a ViewExistingProjectScreen con isNewProject=true
    final projectDataFromDetails = await Navigator.push<ProjectData>(
      context,
      MaterialPageRoute(
        builder: (context) => ViewExistingProjectScreen(
          project: ProjectData(
            userId: widget.userId,
            projectName: _projectNameController.text,
            selectedDate: _selectedDate,
            selectedImage: _selectedImage,
            creatorName: _creatorNameController.text,
            workType: _selectedWorkType,
            resistanceTarget: _selectedResistanceTarget!,
            temperature: _selectedTemperature!,
            humidity: _selectedHumidity!,
            relacionAc: _selectedRelacionAc!,
            aditivoId: _selectedAditivoId,
            resistenciaPredicha7d: resistencias['dias_7'],
            resistenciaPredicha14d: resistencias['dias_14'],
            resistenciaPredicha28d: resistencias['dias_28'],
          ),
          isNewProject: true,
        ),
      ),
    );

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
                  decoration: _inputDecoration(labelText: 'Resistencia objetivo (MPa) - Rango: 24-57'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}\.?\d{0,2}')),
                  ],
                  onChanged: (value) {
                    final double? parsed = double.tryParse(value);
                    setState(() => _selectedResistanceTarget = parsed);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Campo requerido';
                    final double? resistance = double.tryParse(value);
                    if (resistance == null) return 'Ingrese un número válido';
                    if (resistance < 24 || resistance > 57) return 'Debe estar entre 24 y 57 MPa';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: _inputDecoration(labelText: 'Temperatura (°C)'),
                  value: _selectedTemperature,
                  items: _availableTemperatures.map((temp) {
                    String label;
                    if (temp == 10) label = 'Baja (10°C)';
                    else if (temp == 25) label = 'Ambiente (25°C)';
                    else label = 'Alta (32°C)';
                    return DropdownMenuItem(value: temp, child: Text(label));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTemperature = value);
                      _loadHumidityOptions(value);
                    }
                  },
                  validator: (value) => value == null ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: _inputDecoration(labelText: 'Humedad relativa (%)'),
                  value: _selectedHumidity,
                  items: _availableHumidities.map((hum) {
                    return DropdownMenuItem(value: hum, child: Text('$hum%'));
                  }).toList(),
                  onChanged: _selectedTemperature == null ? null : (value) {
                    if (value != null) {
                      setState(() => _selectedHumidity = value);
                      _loadRelacionAcOptions(_selectedTemperature!, value);
                    }
                  },
                  validator: (value) => value == null ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<double>(
                  decoration: _inputDecoration(labelText: 'Relación agua/cemento'),
                  value: _selectedRelacionAc,
                  items: _availableRelacionesAc.map((relacion) {
                    return DropdownMenuItem(value: relacion, child: Text(relacion.toStringAsFixed(2)));
                  }).toList(),
                  onChanged: (_selectedTemperature == null || _selectedHumidity == null) ? null : (value) {
                    if (value != null) {
                      setState(() => _selectedRelacionAc = value);
                      _loadAditivoOptions(_selectedTemperature!, _selectedHumidity!, value);
                    }
                  },
                  validator: (value) => value == null ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: _inputDecoration(labelText: 'Aditivo (opcional)'),
                  value: _selectedAditivoId,
                  items: _availableAditivos.map((aditivo) {
                    return DropdownMenuItem(
                      value: aditivo['id'] as int,
                      child: Text(aditivo['codigo'] as String),
                    );
                  }).toList(),
                  onChanged: (_selectedTemperature == null || _selectedHumidity == null || _selectedRelacionAc == null) 
                    ? null 
                    : (value) => setState(() => _selectedAditivoId = value),
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