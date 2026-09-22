// lib/view/view_existing_project_screen.dart
import 'package:diapce_aplicationn/components/app_button.dart';
import 'package:diapce_aplicationn/components/app_card.dart';
import 'package:diapce_aplicationn/components/bottom_action_bar.dart';
import 'package:diapce_aplicationn/components/fade_slide_in.dart';
import 'package:diapce_aplicationn/components/section_header.dart';
import 'package:diapce_aplicationn/components/stat_tile.dart';
import 'package:diapce_aplicationn/core/database_helper.dart';
import 'package:diapce_aplicationn/core/theme/app_colors.dart';
import 'package:diapce_aplicationn/core/theme/app_spacing.dart';
import 'package:diapce_aplicationn/models/mixture.dart';
import 'package:diapce_aplicationn/models/project_data.dart';
import 'package:diapce_aplicationn/services/mixture_service.dart';
import 'package:diapce_aplicationn/services/project_service.dart';
import 'package:diapce_aplicationn/view/hall.dart' show projectHeroTag;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  List<MaterialInMixture> _materials = [];
  bool _isLoading = true;
  bool _saving = false;
  late ProjectData _currentProject; // Track the current project state

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project; // Initialize with the widget project
    _loadMixtureData();
  }

  Future<void> _loadMixtureData() async {
    if (_currentProject.mixtureId != null) {
      try {
        final mixture = await _mixtureService.getMixtureWithMaterials(
          _currentProject.mixtureId!,
        );
        if (mixture != null && mounted) {
          setState(() {
            _materials = mixture.materials ?? [];
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      // Crear una instancia local de DatabaseHelper
      final dbHelper = DatabaseHelper();
      final mixtureId = await dbHelper.createRandomExampleMixture(
        _currentProject.projectName,
      );

      // Actualizar el proyecto actual con el nuevo mixtureId
      setState(() {
        _currentProject = _currentProject.copyWith(mixtureId: mixtureId);
      });

      // Cargar los materiales de la mezcla recién creada
      try {
        final mixture = await _mixtureService.getMixtureWithMaterials(
          mixtureId,
        );
        if (mixture != null && mounted) {
          setState(() {
            _materials = mixture.materials ?? [];
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _saveProject() async {
    final scheme = Theme.of(context).colorScheme;
    setState(() => _saving = true);
    try {
      // Guardar el proyecto con su mezcla en la base de datos
      final savedProject = await _projectService.saveCompleteProject(_currentProject);

      if (savedProject != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proyecto guardado exitosamente')),
        );
        // Retornar el proyecto guardado a la pantalla anterior
        Navigator.pop(context, savedProject);
      } else {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error al guardar el proyecto'),
              backgroundColor: scheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: scheme.error),
        );
      }
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

  // Crear datos para la gráfica de resistencia vs tiempo (28 días)
  List<FlSpot> _createResistanceData() {
    // Obtener el valor de resistencia del proyecto
    final targetResistance = widget.project.resistanceTarget.toDouble();

    // Datos típicos de desarrollo de resistencia del concreto
    // Porcentajes aproximados de la resistencia final a diferentes días
    final resistancePercentages = {
      1: 0.15, // 15% al día 1
      3: 0.35, // 35% al día 3
      7: 0.65, // 65% a los 7 días
      14: 0.85, // 85% a los 14 días
      21: 0.92, // 92% a los 21 días
      28: 1.0, // 100% a los 28 días (resistencia de diseño)
    };

    List<FlSpot> spots = [];

    // Crear puntos para cada día del 1 al 28
    for (int day = 1; day <= 28; day++) {
      double resistanceRatio;

      if (resistancePercentages.containsKey(day)) {
        resistanceRatio = resistancePercentages[day]!;
      } else {
        // Interpolación para días intermedios
        if (day < 3) {
          resistanceRatio = 0.15 + (0.35 - 0.15) * (day - 1) / (3 - 1);
        } else if (day < 7) {
          resistanceRatio = 0.35 + (0.65 - 0.35) * (day - 3) / (7 - 3);
        } else if (day < 14) {
          resistanceRatio = 0.65 + (0.85 - 0.65) * (day - 7) / (14 - 7);
        } else if (day < 21) {
          resistanceRatio = 0.85 + (0.92 - 0.85) * (day - 14) / (21 - 14);
        } else {
          resistanceRatio = 0.92 + (1.0 - 0.92) * (day - 21) / (28 - 21);
        }
      }

      final resistance = targetResistance * resistanceRatio;
      spots.add(FlSpot(day.toDouble(), resistance));
    }

    return spots;
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
                    subtitle: 'Proporción de la mezcla',
                  ),
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
                  SizedBox(height: 240, child: _buildLineChart(scheme, text)),
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
                            'Curva típica de hidratación: 65 % a 7 días, 85 % a 14 días y 100 % (${project.resistanceTarget} MPa) a los 28 días.',
                            style: text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          if (widget.isNewProject)
            // Con dos acciones, descargar pasa a botón compacto de ícono.
            SizedBox(
              width: 52,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  // Acción de descarga aquí
                },
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                child: const Icon(Icons.download_rounded, size: 22),
              ),
            )
          else
            Expanded(
              child: AppButton.outline(
                label: 'Descargar',
                icon: Icons.download_rounded,
                onPressed: () {
                  // Acción de descarga aquí
                },
              ),
            ),
          if (widget.isNewProject) ...[
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: AppButton(
                label: 'Guardar proyecto',
                icon: Icons.check_rounded,
                loading: _saving,
                onPressed: _saveProject,
              ),
            ),
          ],
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
        maxY: widget.project.resistanceTarget.toDouble() * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: _createResistanceData(),
            isCurved: true,
            color: scheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) => [7, 14, 28].contains(spot.x.toInt()),
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: scheme.primary,
                  strokeWidth: 3,
                  strokeColor: scheme.surface,
                );
              },
            ),
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
        ],
      ),
      duration: AppMotion.slow,
      curve: AppMotion.emphasized,
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
