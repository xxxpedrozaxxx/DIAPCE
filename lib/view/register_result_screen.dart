// lib/view/register_result_screen.dart
//
// Formulario para registrar el ensayo de compresión de un cilindro (NTC 673)
// con sus condiciones ambientales, aditivo y tipo de estructura. Reemplaza el
// registro manual en planillas: el servidor valida los datos, los guarda en
// PostgreSQL y recalibra el modelo (POST /api/experiments/results).
import 'package:diapce_aplicationn/components/app_button.dart';
import 'package:diapce_aplicationn/components/app_card.dart';
import 'package:diapce_aplicationn/components/app_choice_chips.dart';
import 'package:diapce_aplicationn/components/bottom_action_bar.dart';
import 'package:diapce_aplicationn/components/section_header.dart';
import 'package:diapce_aplicationn/core/api_client.dart';
import 'package:diapce_aplicationn/core/estructuras.dart';
import 'package:diapce_aplicationn/core/theme/app_spacing.dart';
import 'package:diapce_aplicationn/services/experiment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class RegisterResultScreen extends StatefulWidget {
  const RegisterResultScreen({super.key});

  @override
  State<RegisterResultScreen> createState() => _RegisterResultScreenState();
}

class _RegisterResultScreenState extends State<RegisterResultScreen> {
  final _formKey = GlobalKey<FormState>();
  final ExperimentService _experiments = ExperimentService();

  final _temperatura = TextEditingController(text: '25');
  final _humedad = TextEditingController(text: '70');
  final _relacionAc = TextEditingController(text: '0.45');
  final _edad = TextEditingController(text: '28');
  final _resistencia = TextEditingController();
  final _observaciones = TextEditingController();
  final _resistenciaFocus = FocusNode();

  List<AditivoCatalogo> _aditivos = [];
  int? _aditivoId;
  String? _estructura;
  DateTime _fecha = DateTime.now();
  bool _saving = false;
  bool _showSelectionErrors = false;
  int _registrados = 0;

  @override
  void initState() {
    super.initState();
    _loadAditivos();
  }

  @override
  void dispose() {
    for (final c in [
      _temperatura,
      _humedad,
      _relacionAc,
      _edad,
      _resistencia,
      _observaciones,
    ]) {
      c.dispose();
    }
    _resistenciaFocus.dispose();
    super.dispose();
  }

  Future<void> _loadAditivos() async {
    try {
      final aditivos = await _experiments.aditivos();
      if (mounted) setState(() => _aditivos = aditivos);
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? scheme.error : null,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.'));

  /// Guarda el ensayo. Con `otro`, conserva las condiciones y limpia solo la
  /// resistencia para registrar el siguiente cilindro de la misma tanda.
  Future<void> _save({required bool otro}) async {
    setState(() => _showSelectionErrors = true);
    final valid = _formKey.currentState!.validate();
    if (!valid || _aditivoId == null || _estructura == null) return;

    setState(() => _saving = true);
    try {
      await _experiments.registerResult({
        'temperatura': _num(_temperatura)!.round(),
        'humedad': _num(_humedad)!.round(),
        'relacion_ac': _num(_relacionAc),
        'edad_dias': _num(_edad)!.round(),
        'resistencia_mpa': _num(_resistencia),
        'aditivo_id': _aditivoId,
        'tipo_estructura': _estructura,
        'fecha_ensayo': DateFormat('yyyy-MM-dd').format(_fecha),
        if (_observaciones.text.trim().isNotEmpty)
          'observaciones': _observaciones.text.trim(),
      });
      _registrados++;
      if (!mounted) return;
      if (otro) {
        setState(() {
          _saving = false;
          _showSelectionErrors = false;
        });
        _resistencia.clear();
        _observaciones.clear();
        _resistenciaFocus.requestFocus();
        _snack('Ensayo $_registrados guardado. Modelo recalibrado.');
      } else {
        Navigator.pop(context, _registrados);
      }
    } on ApiException catch (e) {
      setState(() => _saving = false);
      _snack(e.message, error: true);
    }
  }

  String? _range(String? value, double min, double max, String unit) {
    final v = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (v == null) return 'Campo requerido';
    if (v < min || v > max) return 'Entre ${_fmt(min)} y ${_fmt(max)} $unit';
    return null;
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final decimal = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}[.,]?\d{0,2}')),
    ];
    final entero = [FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,3}'))];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context, _registrados),
        ),
        title: const Text('Registrar ensayo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Text('Resultado de un cilindro', style: text.headlineLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Registra la resistencia a la compresión (NTC 673) junto con las condiciones '
              'de curado. Al guardar, el modelo se recalibra con el dato nuevo.',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Clasificación ─────────────────────────────────────────
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    eyebrow: 'Paso 1',
                    title: 'Tipo de estructura',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppChoiceChips<String>(
                    options: estructuras.map((e) => e.$1).toList(),
                    selected: _estructura,
                    labelBuilder: estructuraLabel,
                    onSelected: (v) => setState(() => _estructura = v),
                  ),
                  if (_showSelectionErrors && _estructura == null)
                    const _Required(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Condiciones ───────────────────────────────────────────
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    eyebrow: 'Paso 2',
                    title: 'Condiciones de la mezcla',
                    subtitle: 'Ambiente de curado, dosificación y aditivo.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _temperatura,
                          decoration: const InputDecoration(
                            labelText: 'Temperatura',
                            suffixText: '°C',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                          ),
                          inputFormatters: entero,
                          validator: (v) => _range(v, -10, 60, '°C'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _humedad,
                          decoration: const InputDecoration(
                            labelText: 'Humedad',
                            suffixText: '%',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: entero,
                          validator: (v) => _range(v, 0, 100, '%'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _relacionAc,
                    decoration: const InputDecoration(
                      labelText: 'Relación agua / cemento',
                      hintText: '0.45',
                      prefixIcon: Icon(Icons.science_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: decimal,
                    validator: (v) => _range(v, 0.2, 1.0, ''),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Aditivo', style: text.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  AppChoiceChips<int>(
                    options: _aditivos.map((a) => a.id).toList(),
                    selected: _aditivoId,
                    labelBuilder:
                        (id) => _aditivos.firstWhere((a) => a.id == id).codigo,
                    captionBuilder: (id) {
                      final a = _aditivos.firstWhere((a) => a.id == id);
                      if (a.porcentaje == '0%') return 'Control';
                      return '${a.tipo.startsWith('Imper') ? 'Imperm.' : 'Plastif.'} ${a.porcentaje}';
                    },
                    emptyHint: 'Cargando catálogo de aditivos…',
                    onSelected: (v) => setState(() => _aditivoId = v),
                  ),
                  if (_showSelectionErrors && _aditivoId == null)
                    const _Required(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Resultado ─────────────────────────────────────────────
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    eyebrow: 'Paso 3',
                    title: 'Resultado del ensayo',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Edad del cilindro', style: text.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  AppChoiceChips<int>(
                    options: const [3, 7, 14, 28, 56],
                    selected: int.tryParse(_edad.text),
                    labelBuilder: (d) => '$d días',
                    onSelected: (d) => setState(() => _edad.text = '$d'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _edad,
                          decoration: const InputDecoration(
                            labelText: 'Edad',
                            suffixText: 'días',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => setState(() {}),
                          validator: (v) => _range(v, 1, 365, 'días'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _resistencia,
                          focusNode: _resistenciaFocus,
                          decoration: const InputDecoration(
                            labelText: 'Resistencia',
                            suffixText: 'MPa',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: decimal,
                          validator: (v) => _range(v, 0.1, 150, 'MPa'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: AppRadius.baseAll,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha del ensayo',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        suffixIcon: Icon(Icons.expand_more_rounded),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(_fecha)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _observaciones,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones (opcional)',
                      hintText: 'Cilindro, tanda, tipo de falla…',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                    maxLength: 500,
                    maxLines: 2,
                    minLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          Expanded(
            child: AppButton.outline(
              label: 'Guardar y otro',
              onPressed: _saving ? null : () => _save(otro: true),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: AppButton(
              label: 'Guardar',
              icon: Icons.check_rounded,
              loading: _saving,
              onPressed: () => _save(otro: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _Required extends StatelessWidget {
  const _Required();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        'Selecciona una opción',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.error),
      ),
    );
  }
}
