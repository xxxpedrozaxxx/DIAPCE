// lib/view/create_project_screen.dart

import 'dart:io';

import 'package:diapce_aplicationn/components/app_button.dart';
import 'package:diapce_aplicationn/components/app_card.dart';
import 'package:diapce_aplicationn/components/app_choice_chips.dart';
import 'package:diapce_aplicationn/components/bottom_action_bar.dart';
import 'package:diapce_aplicationn/components/fade_slide_in.dart';
import 'package:diapce_aplicationn/components/section_header.dart';
import 'package:diapce_aplicationn/core/database_helper.dart';
import 'package:diapce_aplicationn/core/theme/app_spacing.dart';
import 'package:diapce_aplicationn/models/project_data.dart';
import 'package:diapce_aplicationn/view/ViewExistingProjectScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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

  // Opciones disponibles para los selectores
  final List<int> _availableTemperatures = [10, 25, 32];
  List<int> _availableHumidities = [];
  List<double> _availableRelacionesAc = [];
  List<Map<String, dynamic>> _availableAditivos = [];

  static const List<(String value, String label)> _workTypes = [
    ('Puentes', 'Puentes'),
    ('Tuneles', 'Túneles'),
    ('Muros', 'Muros de contención'),
  ];

  // GlobalKey para el Form
  final _formKey = GlobalKey<FormState>();

  // Muestra errores inline en los selectores tras un intento de envío.
  bool _showSelectionErrors = false;
  bool _submitting = false;

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
    setState(() => _showSelectionErrors = true);
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
        _selectedHumidity == null || _selectedRelacionAc == null ||
        _selectedWorkType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todas las condiciones técnicas.')),
      );
      return;
    }

    setState(() => _submitting = true);

    // Calcular resistencias predichas basadas en los datos experimentales
    final db = DatabaseHelper();
    final resistencias = await db.getResistenciaPromedio(
      temperatura: _selectedTemperature!,
      humedad: _selectedHumidity!,
      relacionAc: _selectedRelacionAc!,
      aditivoId: _selectedAditivoId ?? 1, // Si no se seleccionó aditivo, usar el primero
    );

    if (!mounted) return;
    setState(() => _submitting = false);

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

  String _temperatureLabel(int temp) {
    if (temp == 10) return 'Baja';
    if (temp == 25) return 'Ambiente';
    return 'Alta';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Nuevo proyecto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl * 2.5,
          ),
          children: [
            FadeSlideIn(
              index: 0,
              child: Text(
                'Define las\ncondiciones de obra.',
                style: text.headlineLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FadeSlideIn(
              index: 1,
              child: Text(
                'La predicción de resistencia se calcula con datos experimentales que coinciden con tu selección.',
                style: text.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Datos generales ────────────────────────────────────────
            FadeSlideIn(
              index: 2,
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(eyebrow: 'Paso 1', title: 'Datos generales'),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _projectNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del proyecto',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _creatorNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del creador',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GestureDetector(
                      onTap: () => _pickDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          key: ValueKey(_selectedDate),
                          initialValue: _selectedDate == null
                              ? ''
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                          decoration: const InputDecoration(
                            labelText: 'Fecha',
                            hintText: 'Selecciona una fecha',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            suffixIcon: Icon(Icons.expand_more_rounded),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ImagePickerTile(image: _selectedImage, onTap: _pickImage),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Condiciones técnicas ───────────────────────────────────
            FadeSlideIn(
              index: 3,
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      eyebrow: 'Paso 2',
                      title: 'Condiciones técnicas',
                      subtitle: 'Cada selección habilita la siguiente.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _resistanceController,
                      decoration: const InputDecoration(
                        labelText: 'Resistencia objetivo',
                        hintText: '24 – 57',
                        prefixIcon: Icon(Icons.speed_rounded),
                        suffixText: 'MPa',
                      ),
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
                    const SizedBox(height: AppSpacing.lg),

                    _FieldLabel(
                      'Temperatura',
                      error: _showSelectionErrors && _selectedTemperature == null,
                    ),
                    AppChoiceChips<int>(
                      options: _availableTemperatures,
                      selected: _selectedTemperature,
                      labelBuilder: (t) => '$t °C',
                      captionBuilder: _temperatureLabel,
                      onSelected: (value) {
                        setState(() => _selectedTemperature = value);
                        _loadHumidityOptions(value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _FieldLabel(
                      'Humedad relativa',
                      error: _showSelectionErrors && _selectedHumidity == null,
                    ),
                    AppChoiceChips<int>(
                      options: _availableHumidities,
                      selected: _selectedHumidity,
                      labelBuilder: (h) => '$h %',
                      emptyHint: 'Selecciona una temperatura primero',
                      onSelected: (value) {
                        setState(() => _selectedHumidity = value);
                        _loadRelacionAcOptions(_selectedTemperature!, value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _FieldLabel(
                      'Relación agua / cemento',
                      error: _showSelectionErrors && _selectedRelacionAc == null,
                    ),
                    AppChoiceChips<double>(
                      options: _availableRelacionesAc,
                      selected: _selectedRelacionAc,
                      labelBuilder: (r) => r.toStringAsFixed(2),
                      emptyHint: 'Selecciona la humedad primero',
                      onSelected: (value) {
                        setState(() => _selectedRelacionAc = value);
                        _loadAditivoOptions(_selectedTemperature!, _selectedHumidity!, value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    const _FieldLabel('Aditivo', optional: true),
                    AppChoiceChips<int>(
                      options: _availableAditivos.map((a) => a['id'] as int).toList(),
                      selected: _selectedAditivoId,
                      labelBuilder: (id) => _availableAditivos
                          .firstWhere((a) => a['id'] == id)['codigo'] as String,
                      emptyHint: 'Selecciona la relación a/c primero',
                      onSelected: (value) => setState(() => _selectedAditivoId = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _FieldLabel(
                      'Tipo de obra',
                      error: _showSelectionErrors && _selectedWorkType == null,
                    ),
                    AppChoiceChips<String>(
                      options: _workTypes.map((w) => w.$1).toList(),
                      selected: _selectedWorkType,
                      labelBuilder: (v) => _workTypes.firstWhere((w) => w.$1 == v).$2,
                      onSelected: (value) => setState(() => _selectedWorkType = value),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          Expanded(
            child: AppButton.outline(
              label: 'Volver',
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            flex: 2,
            child: AppButton(
              label: 'Siguiente',
              icon: Icons.arrow_forward_rounded,
              loading: _submitting,
              onPressed: _submitAndNavigateToDetails,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets privados ──────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool optional;
  final bool error;

  const _FieldLabel(this.label, {this.optional = false, this.error = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: error ? scheme.error : null,
            ),
          ),
          if (optional) ...[
            const SizedBox(width: AppSpacing.sm),
            Text('Opcional', style: theme.textTheme.labelSmall),
          ],
          if (error) ...[
            const Spacer(),
            Text(
              'Requerido',
              style: theme.textTheme.labelSmall?.copyWith(color: scheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImagePickerTile extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;

  const _ImagePickerTile({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      color: scheme.primaryContainer,
      borderRadius: AppRadius.baseAll,
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: AnimatedSwitcher(
          duration: AppMotion.normal,
          child: image == null
              ? Column(
                  key: const ValueKey('empty'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 32, color: scheme.primary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Agregar imagen de portada',
                      style: text.labelMedium?.copyWith(color: scheme.onPrimaryContainer),
                    ),
                  ],
                )
              : Stack(
                  key: ValueKey(image!.path),
                  fit: StackFit.expand,
                  children: [
                    Image.file(image!, fit: BoxFit.cover),
                    Positioned(
                      right: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2, vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.92),
                          borderRadius: AppRadius.pillAll,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined, size: 14, color: scheme.onSurface),
                            const SizedBox(width: AppSpacing.xs),
                            Text('Cambiar', style: text.labelSmall?.copyWith(color: scheme.onSurface)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
