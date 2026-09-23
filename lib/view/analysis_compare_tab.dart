// lib/view/analysis_compare_tab.dart
//
// Comparación de mezclas: hasta tres combinaciones de condiciones
// (temperatura, humedad, a/c, aditivo) lado a lado, con su curva de
// desarrollo de resistencia y la estadística de los ensayos por edad.
import 'package:diapce_aplicationn/components/app_card.dart';
import 'package:diapce_aplicationn/components/app_choice_chips.dart';
import 'package:diapce_aplicationn/components/section_header.dart';
import 'package:diapce_aplicationn/core/api_client.dart';
import 'package:diapce_aplicationn/core/theme/app_colors.dart';
import 'package:diapce_aplicationn/core/theme/app_spacing.dart';
import 'package:diapce_aplicationn/services/experiment_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Condiciones de una mezcla ensayada.
class _Combo {
  final int temperatura;
  final int humedad;
  final double relacionAc;
  final int aditivoId;
  final String aditivoCodigo;

  const _Combo(
    this.temperatura,
    this.humedad,
    this.relacionAc,
    this.aditivoId,
    this.aditivoCodigo,
  );

  String get label =>
      '$temperatura °C · $humedad % · a/c ${relacionAc.toStringAsFixed(2)} · $aditivoCodigo';
}

const _maxCombos = 3;
const _colores = [AppColors.primary, AppColors.accent, Color(0xFF16A34A)];

class CompareTab extends StatefulWidget {
  const CompareTab({super.key});

  @override
  State<CompareTab> createState() => _CompareTabState();
}

class _CompareTabState extends State<CompareTab>
    with AutomaticKeepAliveClientMixin {
  final ExperimentService _experiments = ExperimentService();

  // Arranca comparando la mejor mezcla con plastificante contra su control.
  final List<_Combo> _combos = [
    const _Combo(25, 70, 0.40, 7, 'PP3'),
    const _Combo(25, 70, 0.40, 1, 'P0'),
  ];
  final Map<_Combo, Prediction> _predicciones = {};
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _combos.forEach(_load);
  }

  Future<void> _load(_Combo c) async {
    try {
      final p = await _experiments.predict(
        temperatura: c.temperatura,
        humedad: c.humedad,
        relacionAc: c.relacionAc,
        aditivoId: c.aditivoId,
      );
      if (mounted) setState(() => _predicciones[c] = p);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _add() async {
    final combo = await showModalBottomSheet<_Combo>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ComboPicker(),
    );
    if (combo == null || _combos.any((c) => c.label == combo.label)) return;
    setState(() => _combos.add(combo));
    _load(combo);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        const SectionHeader(
          eyebrow: 'Comparación de mezclas',
          title: 'Mezclas lado a lado',
          subtitle:
              'Resistencia promedio de los ensayos por edad y curva ajustada de cada mezcla.',
        ),
        const SizedBox(height: AppSpacing.md),
        for (final (i, c) in _combos.indexed) ...[
          AppCard(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _colores[i],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(c.label, style: text.titleSmall)),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Quitar',
                  onPressed:
                      _combos.length <= 1
                          ? null
                          : () => setState(() {
                            _combos.removeAt(i);
                            _predicciones.remove(c);
                          }),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (_combos.length < _maxCombos)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar mezcla'),
            ),
          ),
        if (_error != null)
          Text(_error!, style: text.bodySmall?.copyWith(color: scheme.error)),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: SizedBox(height: 260, child: _buildChart(scheme, text)),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: 'Tabla comparativa',
          subtitle:
              'Promedio ± desviación estándar (MPa) y número de cilindros',
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
              headingTextStyle: text.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              columns: const [
                DataColumn(label: Text('Mezcla')),
                DataColumn(label: Text('7 d'), numeric: true),
                DataColumn(label: Text('14 d'), numeric: true),
                DataColumn(label: Text('28 d'), numeric: true),
                DataColumn(label: Text('n'), numeric: true),
                DataColumn(label: Text('Curva')),
              ],
              rows: [
                for (final (i, c) in _combos.indexed)
                  DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _colores[i],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${c.aditivoCodigo} · ${c.temperatura}°/${c.humedad}%/${c.relacionAc}',
                            ),
                          ],
                        ),
                      ),
                      for (final edad in const [7, 14, 28])
                        DataCell(Text(_stat(_predicciones[c], edad))),
                      DataCell(Text('${_predicciones[c]?.numMuestras ?? '—'}')),
                      DataCell(Text(_predicciones[c]?.formula ?? '—')),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(_conclusion(), style: text.bodySmall),
      ],
    );
  }

  String _stat(Prediction? p, int edad) {
    final s = p?.porEdad.where((e) => e.edadDias == edad).firstOrNull;
    if (s == null) return '—';
    final desv =
        s.desviacion == null ? '' : ' ± ${s.desviacion!.toStringAsFixed(1)}';
    return '${s.promedio.toStringAsFixed(1)}$desv';
  }

  /// Frase que resume qué mezcla es más resistente a 28 días y por cuánto.
  String _conclusion() {
    final con28 = [
      for (final c in _combos)
        if (_predicciones[c]?.dias28 != null) (c, _predicciones[c]!.dias28!),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    if (con28.length < 2) return '';
    final (mejor, v1) = con28.first;
    final (peor, v2) = con28.last;
    final pct = (v1 - v2) / v2 * 100;
    return 'A 28 días, ${mejor.aditivoCodigo} (${mejor.temperatura} °C, ${mejor.humedad} %, a/c '
        '${mejor.relacionAc}) supera a ${peor.aditivoCodigo} (${peor.temperatura} °C, ${peor.humedad} %, '
        'a/c ${peor.relacionAc}) en ${(v1 - v2).toStringAsFixed(1)} MPa (${pct.toStringAsFixed(1)} %).';
  }

  Widget _buildChart(ColorScheme scheme, TextTheme text) {
    final axisStyle = text.labelSmall?.copyWith(letterSpacing: 0);
    final bars = <LineChartBarData>[];
    var maxY = 10.0;
    for (final (i, c) in _combos.indexed) {
      final p = _predicciones[c];
      if (p == null) continue;
      final curva = [
        for (var d = 3; d <= 28; d++)
          if (p.at(d.toDouble()) case final v?) FlSpot(d.toDouble(), v),
      ];
      final puntos = [
        for (final s in p.porEdad) FlSpot(s.edadDias.toDouble(), s.promedio),
      ];
      for (final s in [...curva, ...puntos]) {
        if (s.y > maxY) maxY = s.y;
      }
      bars
        ..add(
          LineChartBarData(
            spots: curva,
            isCurved: true,
            color: _colores[i],
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
          ),
        )
        ..add(
          LineChartBarData(
            spots: puntos,
            color: Colors.transparent,
            barWidth: 0,
            dotData: FlDotData(
              getDotPainter:
                  (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 4.5,
                    color: _colores[i],
                    strokeWidth: 2,
                    strokeColor: scheme.surface,
                  ),
            ),
          ),
        );
    }
    if (bars.isEmpty) return const Center(child: CircularProgressIndicator());

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 28,
        minY: 0,
        maxY: (maxY * 1.1 / 10).ceil() * 10,
        lineBarsData: bars,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine:
              (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              reservedSize: 32,
              getTitlesWidget: (v, _) => Text('${v.toInt()}', style: axisStyle),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              reservedSize: 28,
              getTitlesWidget:
                  (v, meta) => SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text('${v.toInt()}d', style: axisStyle),
                  ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItems:
                (spots) =>
                    spots
                        .map(
                          (s) => LineTooltipItem(
                            '${s.y.toStringAsFixed(1)} MPa',
                            text.labelMedium!.copyWith(
                              color: scheme.onInverseSurface,
                            ),
                          ),
                        )
                        .toList(),
          ),
        ),
      ),
    );
  }
}

/// Selector en cascada de una combinación ensayada (solo muestra opciones con datos).
class _ComboPicker extends StatefulWidget {
  const _ComboPicker();

  @override
  State<_ComboPicker> createState() => _ComboPickerState();
}

class _ComboPickerState extends State<_ComboPicker> {
  final ExperimentService _experiments = ExperimentService();
  List<int> _temps = [];
  List<int> _hums = [];
  List<double> _acs = [];
  List<AditivoOption> _aditivos = [];
  int? _t;
  int? _h;
  double? _ac;

  @override
  void initState() {
    super.initState();
    _experiments.getTemperatures().then(
      (v) => mounted ? setState(() => _temps = v) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Agregar mezcla', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          Text('Temperatura', style: text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          AppChoiceChips<int>(
            options: _temps,
            selected: _t,
            labelBuilder: (v) => '$v °C',
            emptyHint: 'Cargando…',
            onSelected: (v) async {
              setState(() {
                _t = v;
                _h = null;
                _ac = null;
                _hums = [];
                _acs = [];
                _aditivos = [];
              });
              final hums = await _experiments.getHumidityOptions(v);
              if (mounted) setState(() => _hums = hums);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Humedad', style: text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          AppChoiceChips<int>(
            options: _hums,
            selected: _h,
            labelBuilder: (v) => '$v %',
            emptyHint: 'Selecciona la temperatura',
            onSelected: (v) async {
              setState(() {
                _h = v;
                _ac = null;
                _acs = [];
                _aditivos = [];
              });
              final acs = await _experiments.getRelacionAcOptions(_t!, v);
              if (mounted) setState(() => _acs = acs);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Relación a/c', style: text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          AppChoiceChips<double>(
            options: _acs,
            selected: _ac,
            labelBuilder: (v) => v.toStringAsFixed(2),
            emptyHint: 'Selecciona la humedad',
            onSelected: (v) async {
              setState(() {
                _ac = v;
                _aditivos = [];
              });
              final ads = await _experiments.getAditivoOptions(_t!, _h!, v);
              if (mounted) setState(() => _aditivos = ads);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Aditivo', style: text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          AppChoiceChips<AditivoOption>(
            options: _aditivos,
            selected: null,
            labelBuilder: (a) => a.codigo,
            captionBuilder: (a) => a.porcentaje,
            emptyHint: 'Selecciona la relación a/c',
            onSelected:
                (a) => Navigator.pop(
                  context,
                  _Combo(_t!, _h!, _ac!, a.id, a.codigo),
                ),
          ),
        ],
      ),
    );
  }
}
