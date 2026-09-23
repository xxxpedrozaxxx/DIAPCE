// lib/view/view_existing_project_screen.dart
import 'dart:typed_data';

import 'package:diapce_aplicationn/components/app_button.dart';
import 'package:diapce_aplicationn/components/app_card.dart';
import 'package:diapce_aplicationn/components/bottom_action_bar.dart';
import 'package:diapce_aplicationn/components/fade_slide_in.dart';
import 'package:diapce_aplicationn/components/section_header.dart';
import 'package:diapce_aplicationn/components/stat_tile.dart';
import 'package:diapce_aplicationn/core/api_client.dart';
import 'package:diapce_aplicationn/core/theme/app_colors.dart';
import 'package:diapce_aplicationn/core/theme/app_spacing.dart';
import 'package:diapce_aplicationn/models/mixture.dart';
import 'package:diapce_aplicationn/models/project_data.dart';
import 'package:diapce_aplicationn/services/experiment_service.dart';
import 'package:diapce_aplicationn/services/mixture_service.dart';
import 'package:diapce_aplicationn/services/project_service.dart';
import 'package:diapce_aplicationn/view/analysis_screen.dart';
import 'package:diapce_aplicationn/view/hall.dart' show projectHeroTag;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

class ViewExistingProjectScreen extends StatefulWidget {
  final ProjectData project; // Recibirá el objeto ProjectData completo
  final bool isNewProject;
  const ViewExistingProjectScreen({
    super.key,
    required this.project,
    required this.isNewProject,
  });

  @override
  State<ViewExistingProjectScreen> createState() =>
      _ViewExistingProjectScreenState();
}

class _ViewExistingProjectScreenState extends State<ViewExistingProjectScreen> {
  final MixtureService _mixtureService = MixtureService();
  final ProjectService _projectService = ProjectService();
  final ExperimentService _experimentService = ExperimentService();
  List<MaterialInMixture> _materials = [];
  String? _mixtureDescription;
  bool _isLoading = true;
  bool _saving = false;
  bool _downloading = false;
  Prediction? _prediction;
  bool _loadingPrediction = true;
  late ProjectData _currentProject; // Track the current project state

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project; // Initialize with the widget project
    _loadMixtureData();
    _loadPrediction();
  }

  Future<void> _loadMixtureData() async {
    try {
      // Proyecto guardado: su mezcla ya existe en el servidor. Proyecto
      // nuevo: el servidor la dosifica por ACI 211.1 con la relación a/c, el
      // aditivo y el tipo de estructura, sin persistir nada hasta "Guardar".
      final mixture = _currentProject.mixtureId != null
          ? await _mixtureService.getMixtureWithMaterials(_currentProject.mixtureId!)
          : await _mixtureService.previewMixture(
              _currentProject.workType ?? 'Muros',
              _currentProject.relacionAc,
              _currentProject.aditivoId,
            );
      if (!mounted) return;
      setState(() {
        _materials = mixture?.materials ?? [];
        _mixtureDescription = mixture?.description;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Descarga el PDF del proyecto y abre la vista de impresión del sistema,
  /// desde donde se puede guardar como PDF, imprimir o compartir.
  Future<void> _downloadReport() async {
    final id = _currentProject.id;
    if (id == null) return;
    setState(() => _downloading = true);
    try {
      final bytes = Uint8List.fromList(await _projectService.downloadReport(id));
      final nombre = _currentProject.projectName.replaceAll(RegExp(r'[^\w]+'), '_');
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'DIAPCE_$nombre.pdf');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _saveProject() async {
    final scheme = Theme.of(context).colorScheme;
    setState(() => _saving = true);
    try {
      // POST /api/projects: el servidor guarda el proyecto y crea su mezcla.
      final savedProject = await _projectService.createProject(_currentProject);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proyecto guardado exitosamente')),
      );
      // Retornar el proyecto guardado a la pantalla anterior
      Navigator.pop(context, savedProject);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: scheme.error),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No especificada';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _fmt(double? value) => value == null ? '—' : value.toStringAsFixed(1);

  // Crear datos para la gráfica de pastel
  List<PieChartSectionData> _createPieChartSections(TextStyle labelStyle) {
    if (_materials.isEmpty) return [];

    return _materials.asMap().entries.map((entry) {
      final index = entry.key;
      final material = entry.value;
      final percentage = material.percentage ?? 0.0;

      return PieChartSectionData(
        color: AppColors.chartSeries[index % AppColors.chartSeries.length],
        value: percentage,
        // Porciones muy pequeñas no llevan etiqueta para evitar solapamientos.
        title: percentage < 3 ? '' : '${percentage.toStringAsFixed(0)}%',
        radius: 56,
        titleStyle: labelStyle,
      );
    }).toList();
  }

  // Curva de desarrollo de resistencia f(t) = a + b·ln(t) ajustada en el
  // servidor con los ensayos de las condiciones del proyecto (día 3 a 28).
  List<FlSpot> _createResistanceData() {
    final prediction = _prediction;
    if (prediction == null) return [];
    return [
      for (int day = 3; day <= 28; day++)
        if (prediction.at(day.toDouble()) case final value?)
          FlSpot(day.toDouble(), value),
    ];
  }

  // Promedio real de los ensayos a 7, 14 y 28 días.
  List<FlSpot> _createMeasuredData() => [
        for (final stat in _prediction?.porEdad ?? const <AgeStat>[])
          FlSpot(stat.edadDias.toDouble(), stat.promedio),
      ];

  Future<void> _loadPrediction() async {
    final project = widget.project;
    try {
      final prediction = await _experimentService.predict(
        temperatura: project.temperature,
        humedad: project.humidity,
        relacionAc: project.relacionAc,
        aditivoId: project.aditivoId ?? 1,
      );
      if (!mounted) return;
      setState(() {
        _prediction = prediction;
        _loadingPrediction = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() => _loadingPrediction = false);
    }
  }

  void _openOptimalRanges() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisScreen(
          initialTarget: widget.project.resistanceTarget.toDouble(),
          initialTab: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final project = widget.project;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isNewProject ? 'Vista previa' : 'Proyecto'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl,
        ),
        children: [
          // ── Portada (Hero desde la tarjeta) ──────────────────────────
          if (project.selectedImage != null) ...[
            FadeSlideIn(
              index: 0,
              child: Hero(
                tag: projectHeroTag(project),
                child: ClipRRect(
                  borderRadius: AppRadius.cardAll,
                  child: Image.file(
                    project.selectedImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Título editorial ─────────────────────────────────────────
          FadeSlideIn(
            index: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (project.workType != null)
                  Text(
                    project.workType!.toUpperCase(),
                    style: text.labelSmall?.copyWith(color: scheme.primary),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(project.projectName, style: text.displayMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${project.creatorName?.isNotEmpty == true ? project.creatorName : 'Sin creador'} · ${_formatDate(project.selectedDate)}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Predicción de resistencia (dato protagonista) ────────────
          FadeSlideIn(
            index: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  eyebrow: 'Predicción',
                  title: 'Resistencia estimada',
                  subtitle: 'Objetivo: ${project.resistanceTarget} MPa a 28 días',
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: '7 días',
                        value: _fmt(project.resistenciaPredicha7d),
                        unit: 'MPa',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: StatTile(
                        label: '14 días',
                        value: _fmt(project.resistenciaPredicha14d),
                        unit: 'MPa',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: StatTile(
                        label: '28 días',
                        value: _fmt(project.resistenciaPredicha28d),
                        unit: 'MPa',
                        highlight: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Condiciones ──────────────────────────────────────────────
          FadeSlideIn(
            index: 3,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Condiciones de obra'),
                  const SizedBox(height: AppSpacing.md),
                  _DetailGrid(items: [
                    _DetailItem(Icons.thermostat_rounded, 'Temperatura', '${project.temperature} °C'),
                    _DetailItem(Icons.water_drop_outlined, 'Humedad', '${project.humidity} %'),
                    _DetailItem(Icons.science_outlined, 'Relación a/c', project.relacionAc.toStringAsFixed(2)),
                    _DetailItem(Icons.speed_rounded, 'Objetivo', '${project.resistanceTarget} MPa'),
                    _DetailItem(Icons.domain_rounded, 'Tipo de obra', project.workType ?? 'No especificado'),
                    _DetailItem(Icons.person_outline_rounded, 'Creador', project.creatorName ?? 'No especificado'),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Composición de materiales ────────────────────────────────
          FadeSlideIn(
            index: 4,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Composición de materiales',
                    subtitle: 'Dosificación por m³ (método ACI 211.1)',
                  ),
                  if (_mixtureDescription != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(_mixtureDescription!, style: text.bodySmall),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AnimatedSwitcher(
                    duration: AppMotion.normal,
                    child: _isLoading
                        ? const Padding(
                            key: ValueKey('loading'),
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _materials.isEmpty
                            ? Padding(
                                key: const ValueKey('empty'),
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                child: Center(
                                  child: Text(
                                    'No hay datos de mezcla disponibles',
                                    style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                                  ),
                                ),
                              )
                            : Column(
                                key: const ValueKey('data'),
                                children: [
                                  SizedBox(
                                    height: 180,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: PieChart(
                                            PieChartData(
                                              sections: _createPieChartSections(
                                                text.labelSmall!.copyWith(color: Colors.white),
                                              ),
                                              borderData: FlBorderData(show: false),
                                              sectionsSpace: 3,
                                              centerSpaceRadius: 26,
                                            ),
                                            swapAnimationDuration: AppMotion.slow,
                                            swapAnimationCurve: AppMotion.emphasized,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(flex: 3, child: _buildPieChartLegend()),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  const Divider(),
                                  const SizedBox(height: AppSpacing.sm),
                                  for (final entry in _materials.asMap().entries)
                                    _MaterialRow(
                                      material: entry.value,
                                      color: AppColors.chartSeries[entry.key % AppColors.chartSeries.length],
                                    ),
                                ],
                              ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Gráfica de resistencia ───────────────────────────────────
          FadeSlideIn(
            index: 5,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Desarrollo de resistencia',
                    subtitle: 'MPa vs. tiempo · 28 días',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 240,
                    child: _loadingPrediction
                        ? const Center(child: CircularProgressIndicator())
                        : _prediction?.a == null
                            ? Center(
                                child: Text(
                                  'Sin ensayos suficientes para ajustar la curva.',
                                  style: text.bodySmall,
                                ),
                              )
                            : _buildLineChart(scheme, text),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _ChartLegend(color: scheme.primary, label: 'Curva ajustada'),
                      _ChartLegend(color: AppColors.accent, label: 'Promedio de ensayos'),
                      _ChartLegend(color: scheme.error, label: 'Objetivo', line: true),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: AppRadius.baseAll,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: scheme.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _prediction?.formula == null
                                ? 'La curva se ajusta con los ensayos de laboratorio de estas condiciones.'
                                : 'Modelo ${_prediction!.formula} · R² ${_prediction!.r2?.toStringAsFixed(3) ?? '—'} · '
                                    '${_prediction!.numMuestras} ensayos (T ${project.temperature} °C, '
                                    'HR ${project.humidity} %, a/c ${project.relacionAc}).',
                            style: text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton.outline(
                    label: 'Rangos óptimos para ${project.resistanceTarget} MPa',
                    icon: Icons.tune_rounded,
                    onPressed: _openOptimalRanges,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          // El reporte se genera en el servidor, así que solo existe para
          // proyectos guardados; en la vista previa la acción es guardar.
          if (widget.isNewProject)
            Expanded(
              child: AppButton(
                label: 'Guardar proyecto',
                icon: Icons.check_rounded,
                loading: _saving,
                onPressed: _saveProject,
              ),
            )
          else
            Expanded(
              child: AppButton.outline(
                label: 'Descargar reporte PDF',
                icon: Icons.picture_as_pdf_rounded,
                loading: _downloading,
                onPressed: _downloadReport,
              ),
            ),
        ],
      ),
    );
  }

  // Widget para mostrar la leyenda de la gráfica
  Widget _buildPieChartLegend() {
    if (_materials.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _materials.asMap().entries.map((entry) {
        final index = entry.key;
        final material = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.chartSeries[index % AppColors.chartSeries.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  material.materialName,
                  style: text.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineChart(ColorScheme scheme, TextTheme text) {
    final axisStyle = text.labelSmall?.copyWith(letterSpacing: 0);
    final gridColor = scheme.outlineVariant;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) => FlLine(color: gridColor, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 7,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text('${value.toInt()}d', style: axisStyle),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: axisStyle);
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(1)} MPa\ndía ${s.x.toInt()}',
                      text.labelMedium!.copyWith(color: scheme.onInverseSurface),
                    ))
                .toList(),
          ),
        ),
        minX: 0,
        maxX: 28,
        minY: 0,
        maxY: _chartMaxY(),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: widget.project.resistanceTarget.toDouble(),
              color: scheme.error.withValues(alpha: 0.7),
              strokeWidth: 1.5,
              dashArray: [6, 4],
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _createResistanceData(),
            isCurved: true,
            color: scheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.25),
                  scheme.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Promedios medidos en laboratorio (solo puntos).
          LineChartBarData(
            spots: _createMeasuredData(),
            color: Colors.transparent,
            barWidth: 0,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 5,
                color: AppColors.accent,
                strokeWidth: 2.5,
                strokeColor: scheme.surface,
              ),
            ),
          ),
        ],
      ),
      duration: AppMotion.slow,
      curve: AppMotion.emphasized,
    );
  }

  double _chartMaxY() {
    final values = [
      widget.project.resistanceTarget.toDouble(),
      ..._createResistanceData().map((s) => s.y),
      ..._createMeasuredData().map((s) => s.y),
    ];
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max * 1.15 / 10).ceil() * 10;
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool line;

  const _ChartLegend({required this.color, required this.label, this.line = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: line ? 16 : 10,
          height: line ? 2 : 10,
          decoration: BoxDecoration(
            color: color,
            shape: line ? BoxShape.rectangle : BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

// ── Widgets privados ──────────────────────────────────────────────────────

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem(this.icon, this.label, this.value);
}

/// Rejilla de 2 columnas con ícono, etiqueta y valor.
class _DetailGrid extends StatelessWidget {
  final List<_DetailItem> items;
  const _DetailGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(item.icon, size: 18, color: scheme.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label, style: text.labelSmall),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: text.titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MaterialRow extends StatelessWidget {
  final MaterialInMixture material;
  final Color color;
  const _MaterialRow({required this.material, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final percentage = material.percentage ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(material.materialName, style: text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${material.quantity.toStringAsFixed(1)} ${material.unit}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: AppRadius.pillAll,
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)} %',
              style: text.labelMedium?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
