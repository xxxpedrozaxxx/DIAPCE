// lib/view/analysis_screen.dart
//
// Módulo de visualización (objetivo 3): gráficas y tablas de dispersión de
// los ensayos de laboratorio, y rangos de valores óptimos de las variables
// experimentales (temperatura, humedad, relación a/c, tipo y cantidad de
// aditivo) para una resistencia objetivo. Los cálculos corren en el servidor
// (/api/experiments/dispersion y /api/experiments/optimal-ranges).
import 'package:diapce_aplicationn/components/app_card.dart';
import 'package:diapce_aplicationn/components/app_choice_chips.dart';
import 'package:diapce_aplicationn/components/fade_slide_in.dart';
import 'package:diapce_aplicationn/components/section_header.dart';
import 'package:diapce_aplicationn/components/stat_tile.dart';
import 'package:diapce_aplicationn/core/api_client.dart';
import 'package:diapce_aplicationn/core/estructuras.dart';
import 'package:diapce_aplicationn/core/theme/app_colors.dart';
import 'package:diapce_aplicationn/core/theme/app_spacing.dart';
import 'package:diapce_aplicationn/services/experiment_service.dart';
import 'package:diapce_aplicationn/view/analysis_calibration_tab.dart';
import 'package:diapce_aplicationn/view/analysis_compare_tab.dart';
import 'package:diapce_aplicationn/view/analysis_optimize_tab.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Variable experimental que se grafica en el eje X.
class _Variable {
  final String key;
  final String label;
  final String unit;
  final double axisStep;
  final int decimals;

  const _Variable(this.key, this.label, this.unit, this.axisStep, this.decimals);

  String format(double v) => '${v.toStringAsFixed(decimals)}$unit';
}

const _variables = [
  // Espacio sin salto ( ) para que el valor y su unidad no se separen.
  _Variable('temperatura', 'Temperatura', ' °C', 1, 0),
  _Variable('humedad', 'Humedad', ' %', 5, 0),
  _Variable('relacion_ac', 'Relación a/c', '', 0.05, 2),
  _Variable('porcentaje_aditivo', 'Cantidad de aditivo', ' %', 0.1, 1),
];

const _edades = [7, 14, 28];

/// Color fijo por tipo de aditivo, igual en la gráfica y en la leyenda.
Color _tipoColor(String tipo, ColorScheme scheme) => switch (tipo) {
      'Impermeabilizante' => AppColors.primary,
      'Plastificante' => AppColors.accent,
      _ => scheme.onSurfaceVariant,
    };

String _num(double? v, [int decimals = 2]) => v == null ? '—' : v.toStringAsFixed(decimals);

class AnalysisScreen extends StatelessWidget {
  /// Resistencia objetivo con la que abre la pestaña de rangos óptimos.
  final double? initialTarget;

  /// 0 = dispersión, 1 = rangos óptimos, 2 = optimizar, 3 = comparar, 4 = calibración.
  final int initialTab;

  const AnalysisScreen({super.key, this.initialTarget, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Análisis de laboratorio'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.scatter_plot_rounded), text: 'Dispersión'),
              Tab(icon: Icon(Icons.tune_rounded), text: 'Rangos óptimos'),
              Tab(icon: Icon(Icons.auto_fix_high_rounded), text: 'Optimizar'),
              Tab(icon: Icon(Icons.compare_arrows_rounded), text: 'Comparar'),
              Tab(icon: Icon(Icons.model_training_rounded), text: 'Calibración'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _DispersionTab(),
            _OptimalRangesTab(initialTarget: initialTarget ?? 45),
            const OptimizeTab(),
            const CompareTab(),
            const CalibrationTab(),
          ],
        ),
      ),
    );
  }
}

// ── Dispersión ─────────────────────────────────────────────────────────────

class _DispersionTab extends StatefulWidget {
  const _DispersionTab();

  @override
  State<_DispersionTab> createState() => _DispersionTabState();
}

class _DispersionTabState extends State<_DispersionTab>
    with AutomaticKeepAliveClientMixin {
  final ExperimentService _experiments = ExperimentService();

  _Variable _variable = _variables.first;
  int _edad = 28;
  String? _tipo; // null = todos los aditivos
  List<String> _tipos = [];
  String? _estructura; // null = todas
  Dispersion? _data;
  Anova? _anova;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _experiments.dispersion(
        variable: _variable.key,
        edadDias: _edad,
        tipoAditivo: _tipo,
        tipoEstructura: _estructura,
      );
      // La ANOVA usa todos los ensayos de la edad elegida (sin filtros).
      if (_anova?.edadDias != _edad) {
        _anova = await _experiments.anova(edadDias: _edad);
      }
      if (!mounted) return;
      setState(() {
        _data = data;
        // La lista de tipos sale de la consulta sin filtro.
        if (_tipo == null) _tipos = data.tiposAditivo;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final data = _data;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl,
        ),
        children: [
          FadeSlideIn(
            child: SectionHeader(
              eyebrow: 'Ensayos de laboratorio',
              title: 'Resistencia vs. ${_variable.label.toLowerCase()}',
              subtitle: 'Cada punto es un cilindro ensayado a $_edad días.',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Variable', style: text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          AppChoiceChips<_Variable>(
            options: _variables,
            selected: _variable,
            labelBuilder: (v) => v.label,
            onSelected: (v) {
              setState(() => _variable = v);
              _load();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Edad del ensayo', style: text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          AppChoiceChips<int>(
            options: _edades,
            selected: _edad,
            labelBuilder: (e) => '$e días',
            onSelected: (e) {
              setState(() => _edad = e);
              _load();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Tipo de aditivo', style: text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          AppChoiceChips<String?>(
            options: [null, ..._tipos],
            selected: _tipo,
            labelBuilder: (t) => t ?? 'Todos',
            onSelected: (t) {
              setState(() => _tipo = t);
              _load();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _EstructuraFilter(
            selected: _estructura,
            onSelected: (e) {
              setState(() => _estructura = e);
              _load();
            },
          ),
          if (_variable.key == 'porcentaje_aditivo' && _tipo == null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Las dosis de impermeabilizante (2–4 %) y plastificante (0,2–0,6 %) no son '
              'comparables entre sí; filtra por tipo para leer la tendencia de cada uno.',
              style: text.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (_loading && data == null)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _ErrorCard(message: _error!, onRetry: _load)
          else if (data != null) ...[
            Row(
              children: [
                Expanded(
                  child: StatTile(label: 'Ensayos', value: '${data.numPuntos}'),
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: StatTile(
                    label: 'Correlación r',
                    value: _num(data.correlacion),
                    highlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(_correlationText(data.correlacion), style: text.bodySmall),
            const SizedBox(height: AppSpacing.md),
            AnimatedOpacity(
              opacity: _loading ? 0.4 : 1,
              duration: AppMotion.normal,
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.lg, AppSpacing.md, AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 280,
                      child: data.puntos.isEmpty
                          ? Center(child: Text('Sin ensayos', style: text.bodySmall))
                          : _ScatterPlot(data: data, variable: _variable),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final t in data.tiposAditivo)
                            _LegendDot(color: _tipoColor(t, scheme), label: t),
                          _LegendDot(
                            color: scheme.onSurface,
                            label: 'Promedio',
                            square: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(
              title: 'Tabla de dispersión',
              subtitle: 'Resistencia (MPa) por valor de ${_variable.label.toLowerCase()}',
              titleStyle: text.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 18,
                  headingRowHeight: 40,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 40,
                  headingTextStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                  columns: [
                    DataColumn(label: Text(_variable.label)),
                    const DataColumn(label: Text('n'), numeric: true),
                    const DataColumn(label: Text('Prom.'), numeric: true),
                    const DataColumn(label: Text('Desv. est.'), numeric: true),
                    const DataColumn(label: Text('CV %'), numeric: true),
                    const DataColumn(label: Text('Mín.'), numeric: true),
                    const DataColumn(label: Text('Máx.'), numeric: true),
                    const DataColumn(label: Text('Rango'), numeric: true),
                  ],
                  rows: [
                    for (final r in data.tabla)
                      DataRow(cells: [
                        DataCell(Text(_variable.format(r.valor))),
                        DataCell(Text('${r.numMuestras}')),
                        DataCell(Text(_num(r.promedio))),
                        DataCell(Text(_num(r.desviacion))),
                        DataCell(Text(_num(r.coefVariacion, 1))),
                        DataCell(Text(_num(r.minimo))),
                        DataCell(Text(_num(r.maximo))),
                        DataCell(Text(_num(r.rango))),
                      ]),
                  ],
                ),
              ),
            ),
            if (_anova != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: 'Análisis de varianza (ANOVA)',
                subtitle: 'Efecto de cada factor en la resistencia a $_edad días (${_anova!.n} ensayos)',
                titleStyle: text.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              _AnovaTable(anova: _anova!),
            ],
          ],
        ],
      ),
    );
  }

  String _correlationText(double? r) {
    if (r == null) return 'Sin variación suficiente para calcular la correlación.';
    final abs = r.abs();
    final fuerza = abs < 0.3 ? 'débil' : (abs < 0.7 ? 'moderada' : 'fuerte');
    final sentido = r >= 0 ? 'aumentar' : 'disminuir';
    return 'Correlación $fuerza: la resistencia tiende a $sentido cuando '
        '${_variable.label.toLowerCase()} aumenta.';
  }
}

class _ScatterPlot extends StatelessWidget {
  final Dispersion data;
  final _Variable variable;

  const _ScatterPlot({required this.data, required this.variable});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final axisStyle = theme.textTheme.labelSmall?.copyWith(letterSpacing: 0);

    final xs = data.tabla.map((r) => r.valor).toList();
    final minX = xs.reduce((a, b) => a < b ? a : b);
    final maxX = xs.reduce((a, b) => a > b ? a : b);
    final span = maxX - minX == 0 ? 1.0 : maxX - minX;
    // Margen en múltiplos del paso del eje: así las marcas del eje X caen
    // exactamente sobre los valores ensayados.
    final step = variable.axisStep;
    final pad = ((span * 0.1) / step).ceil() * step;
    // Desplazamiento horizontal pequeño y determinista para que los ensayos
    // con el mismo valor no queden uno encima de otro.
    final jitter = span * 0.018;

    final ys = data.puntos.map((p) => p.y);
    // Límites en múltiplos de 5 para que coincidan con las marcas del eje.
    final minY = ((ys.reduce((a, b) => a < b ? a : b) - 1) / 5).floorToDouble() * 5;
    final maxY = ((ys.reduce((a, b) => a > b ? a : b) + 1) / 5).ceilToDouble() * 5;

    final spots = <ScatterSpot>[
      for (var i = 0; i < data.puntos.length; i++)
        ScatterSpot(
          data.puntos[i].x + ((i * 37) % 11 - 5) / 5 * jitter,
          data.puntos[i].y,
          dotPainter: FlDotCirclePainter(
            radius: 3.2,
            color: _tipoColor(data.puntos[i].tipoAditivo, scheme).withValues(alpha: 0.55),
            strokeWidth: 0,
          ),
        ),
      for (final r in data.tabla)
        ScatterSpot(
          r.valor,
          r.promedio,
          dotPainter: FlDotSquarePainter(
            size: 11,
            color: scheme.onSurface,
            strokeWidth: 2,
            strokeColor: scheme.surface,
          ),
        ),
    ];

    double? tickValue(double value) {
      for (final x in xs) {
        if ((x - value).abs() < step * 0.1) return x;
      }
      return null;
    }

    return ScatterChart(
      ScatterChartData(
        scatterSpots: spots,
        minX: minX - pad,
        maxX: maxX + pad,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            axisNameWidget: Text('MPa', style: axisStyle),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: axisStyle),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: variable.axisStep,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final x = tickValue(value);
                if (x == null) return const SizedBox.shrink();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(variable.format(x), style: axisStyle),
                );
              },
            ),
          ),
        ),
        scatterTouchData: ScatterTouchData(
          enabled: true,
          touchTooltipData: ScatterTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItems: (spot) => ScatterTooltipItem(
              '${spot.y.toStringAsFixed(1)} MPa',
              textStyle: theme.textTheme.labelMedium?.copyWith(color: scheme.onInverseSurface),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Rangos óptimos ─────────────────────────────────────────────────────────

class _OptimalRangesTab extends StatefulWidget {
  final double initialTarget;
  const _OptimalRangesTab({required this.initialTarget});

  @override
  State<_OptimalRangesTab> createState() => _OptimalRangesTabState();
}

class _OptimalRangesTabState extends State<_OptimalRangesTab>
    with AutomaticKeepAliveClientMixin {
  final ExperimentService _experiments = ExperimentService();

  late double _target = widget.initialTarget.clamp(24, 57).roundToDouble();
  String? _estructura; // null = todas
  OptimalRanges? _data;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _experiments.optimalRanges(_target, tipoEstructura: _estructura);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final data = _data;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl,
      ),
      children: [
        FadeSlideIn(
          child: SectionHeader(
            eyebrow: 'Resistencia a 28 días',
            title: 'Rangos de valores óptimos',
            subtitle:
                'Condiciones cuyos ensayos promedian al menos ${_target.toStringAsFixed(0)} MPa.',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Resistencia objetivo', style: text.labelLarge),
                  const Spacer(),
                  Text(
                    '${_target.toStringAsFixed(0)} MPa',
                    style: text.titleLarge?.copyWith(color: scheme.primary),
                  ),
                ],
              ),
              Slider(
                value: _target,
                min: 24,
                max: 57,
                divisions: 33,
                label: '${_target.toStringAsFixed(0)} MPa',
                onChanged: (v) => setState(() => _target = v),
                onChangeEnd: (_) => _load(),
              ),
              _EstructuraFilter(
                selected: _estructura,
                onSelected: (e) {
                  setState(() => _estructura = e);
                  _load();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_loading && data == null)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          _ErrorCard(message: _error!, onRetry: _load)
        else if (data != null)
          AnimatedOpacity(
            opacity: _loading ? 0.4 : 1,
            duration: AppMotion.normal,
            child: _buildResults(data, scheme, text),
          ),
      ],
    );
  }

  Widget _buildResults(OptimalRanges data, ColorScheme scheme, TextTheme text) {
    final pct = data.totalCombinaciones == 0
        ? 0.0
        : data.combinacionesQueCumplen / data.totalCombinaciones * 100;

    if (data.combinacionesQueCumplen == 0) {
      return _InfoCard(
        icon: Icons.search_off_rounded,
        message: 'Ninguna combinación ensayada alcanza ${data.objetivo.toStringAsFixed(0)} MPa '
            'a 28 días (de ${data.totalCombinaciones} combinaciones).',
      );
    }

    String values(String key, _Variable v) =>
        (data.valores[key] ?? []).map(v.format).join(' · ');
    String range(String key, _Variable v) {
      final vals = data.valores[key] ?? [];
      if (vals.isEmpty) return '—';
      return vals.length == 1
          ? v.format(vals.first)
          : '${v.format(vals.first)} – ${v.format(vals.last)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Cumplen',
                value: '${data.combinacionesQueCumplen}',
                unit: 'de ${data.totalCombinaciones}',
                highlight: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: StatTile(label: 'Proporción', value: pct.toStringAsFixed(0), unit: '%'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: 'Variables experimentales',
          subtitle: 'Mínimo – máximo de los valores que alcanzan el objetivo',
          titleStyle: text.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              _RangeRow(
                icon: Icons.thermostat_rounded,
                label: 'Temperatura',
                range: range('temperatura', _variables[0]),
                values: values('temperatura', _variables[0]),
              ),
              const Divider(height: AppSpacing.lg),
              _RangeRow(
                icon: Icons.water_drop_rounded,
                label: 'Humedad',
                range: range('humedad', _variables[1]),
                values: values('humedad', _variables[1]),
              ),
              const Divider(height: AppSpacing.lg),
              _RangeRow(
                icon: Icons.science_rounded,
                label: 'Relación a/c',
                range: range('relacion_ac', _variables[2]),
                values: values('relacion_ac', _variables[2]),
              ),
              for (final a in data.aditivos) ...[
                const Divider(height: AppSpacing.lg),
                _RangeRow(
                  icon: Icons.opacity_rounded,
                  iconColor: _tipoColor(a.tipoAditivo, scheme),
                  label: a.tipoAditivo,
                  range: a.min == a.max
                      ? _variables[3].format(a.min)
                      : '${_variables[3].format(a.min)} – ${_variables[3].format(a.max)}',
                  values: '${a.combinaciones} '
                      '${a.combinaciones == 1 ? 'combinación' : 'combinaciones'} · '
                      '${a.valores.map(_variables[3].format).join(' · ')}',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: 'Mejores combinaciones',
          subtitle: 'Mayor resistencia promedio a 28 días',
          titleStyle: text.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              headingRowHeight: 40,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 40,
              headingTextStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              columns: const [
                DataColumn(label: Text('#'), numeric: true),
                DataColumn(label: Text('T (°C)'), numeric: true),
                DataColumn(label: Text('HR (%)'), numeric: true),
                DataColumn(label: Text('a/c'), numeric: true),
                DataColumn(label: Text('Aditivo')),
                DataColumn(label: Text('Dosis'), numeric: true),
                DataColumn(label: Text('f\'c 28 d'), numeric: true),
                DataColumn(label: Text('n'), numeric: true),
              ],
              rows: [
                for (final (i, c) in data.mejores.indexed)
                  DataRow(cells: [
                    DataCell(Text('${i + 1}')),
                    DataCell(Text('${c.temperatura}')),
                    DataCell(Text('${c.humedad}')),
                    DataCell(Text(c.relacionAc.toStringAsFixed(2))),
                    DataCell(Text('${c.aditivoCodigo} · ${c.tipoAditivo}')),
                    DataCell(Text('${_num(c.porcentajeAditivo, 1)} %')),
                    DataCell(Text(
                      _num(c.promedio28d),
                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                    )),
                    DataCell(Text('${c.numMuestras}')),
                  ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widgets privados ──────────────────────────────────────────────────────

/// Tabla ANOVA: F, p y η² parcial por factor; resalta los efectos significativos.
class _AnovaTable extends StatelessWidget {
  final Anova anova;
  const _AnovaTable({required this.anova});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    String p(double? v) => v == null ? '—' : (v < 0.001 ? '< 0,001' : v.toStringAsFixed(3).replaceAll('.', ','));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowHeight: 40,
              headingTextStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              columns: const [
                DataColumn(label: Text('Fuente')),
                DataColumn(label: Text('gl'), numeric: true),
                DataColumn(label: Text('F'), numeric: true),
                DataColumn(label: Text('p'), numeric: true),
                DataColumn(label: Text('η² parcial'), numeric: true),
              ],
              rows: [
                for (final f in anova.filas)
                  DataRow(cells: [
                    DataCell(Text(f.fuente,
                        style: f.significativo ? const TextStyle(fontWeight: FontWeight.w700) : null)),
                    DataCell(Text('${f.gl}')),
                    DataCell(Text(_num(f.f, 1))),
                    DataCell(Text(p(f.p))),
                    DataCell(Text(_num(f.eta2Parcial, 3))),
                  ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Sumas de cuadrados tipo II (diseño desbalanceado). En negrita, efectos significativos (p < 0,05). '
          'η² parcial indica la proporción de la variación que explica cada factor. R² del modelo: '
          '${_num(anova.r2, 3)}.',
          style: text.bodySmall,
        ),
      ],
    );
  }
}

/// Filtro por tipo de estructura (los ensayos históricos no están clasificados).
class _EstructuraFilter extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _EstructuraFilter({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo de estructura', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        AppChoiceChips<String?>(
          options: filtrosEstructura,
          selected: selected,
          labelBuilder: filtroEstructuraLabel,
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _RangeRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String range;
  final String values;

  const _RangeRow({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.range,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 22, color: iconColor ?? scheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.titleSmall),
              const SizedBox(height: 2),
              Text(values, style: text.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(range, style: text.titleMedium?.copyWith(color: scheme.primary)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool square;

  const _LegendDot({required this.color, required this.label, this.square = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: square ? BoxShape.rectangle : BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InfoCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoCard(icon: Icons.cloud_off_rounded, message: message),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reintentar'),
        ),
      ],
    );
  }
}
