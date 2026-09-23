// lib/view/analysis_calibration_tab.dart
//
// Calibración y retroalimentación del modelo (objetivo específico 4): error
// del modelo f(t) = a + b·ln(t) sobre cilindros que no vio (validación
// cruzada dejando uno fuera), comparado con el modelo base de promedio por
// edad, e historial de recalibraciones a medida que se registran ensayos.
import 'package:diapce_aplicationn/components/app_card.dart';
import 'package:diapce_aplicationn/components/section_header.dart';
import 'package:diapce_aplicationn/components/stat_tile.dart';
import 'package:diapce_aplicationn/core/api_client.dart';
import 'package:diapce_aplicationn/core/theme/app_colors.dart';
import 'package:diapce_aplicationn/core/theme/app_spacing.dart';
import 'package:diapce_aplicationn/services/experiment_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String _f(double? v, [int d = 2]) => v == null ? '—' : v.toStringAsFixed(d);

const _motivos = {
  'semilla': 'Carga inicial',
  'registro': 'Ensayo registrado',
  'importacion': 'Importación CSV',
  'eliminacion': 'Ensayo eliminado',
  'manual': 'Recalibración manual',
};

class CalibrationTab extends StatefulWidget {
  const CalibrationTab({super.key});

  @override
  State<CalibrationTab> createState() => _CalibrationTabState();
}

class _CalibrationTabState extends State<CalibrationTab>
    with AutomaticKeepAliveClientMixin {
  final ExperimentService _experiments = ExperimentService();
  Calibration? _cal;
  List<CalibrationRun> _history = [];
  bool _loading = true;
  bool _running = false;
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
      final results = await Future.wait([
        _experiments.calibration(),
        _experiments.calibrationHistory(),
      ]);
      if (!mounted) return;
      setState(() {
        _cal = results[0] as Calibration;
        _history = results[1] as List<CalibrationRun>;
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

  Future<void> _recalibrate() async {
    setState(() => _running = true);
    try {
      await _experiments.runCalibration();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modelo recalibrado con todos los ensayos.'),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final text = theme.textTheme;

    if (_loading && _cal == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_cal == null) {
      return Center(
        child: TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: Text('$_error\nReintentar', textAlign: TextAlign.center),
        ),
      );
    }
    final cal = _cal!;
    final v = cal.curvaLog.global;
    final base = cal.promedioEdad.global;
    final mejora =
        (base.mae != null && v.mae != null && base.mae! > 0)
            ? (base.mae! - v.mae!) / base.mae! * 100
            : null;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          SectionHeader(
            eyebrow: 'Retroalimentación del modelo',
            title: 'Calibración',
            subtitle:
                'Modelo f(t) = a + b·ln(t) ajustado por mínimos cuadrados para cada combinación '
                '(${cal.combinaciones} combinaciones, ${cal.numEnsayos} cilindros).',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'MAE validación',
                  value: _f(v.mae),
                  unit: 'MPa',
                  highlight: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: StatTile(
                  label: 'RMSE validación',
                  value: _f(v.rmse),
                  unit: 'MPa',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'MAPE validación',
                  value: _f(v.mape, 1),
                  unit: '%',
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: StatTile(
                  label: 'MAE ajuste',
                  value: _f(cal.maeAjuste),
                  unit: 'MPa',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Text(
              'Validación cruzada dejando un cilindro fuera: cada cilindro se predice con un modelo '
              'ajustado sin él, así que el error refleja cómo se comporta el modelo con un ensayo nuevo. '
              'El error de ajuste (${_f(cal.maeAjuste)} MPa) y el R² promedio (${_f(cal.r2Promedio, 3)}) '
              'son optimistas porque la curva se ajusta con solo tres edades.'
              '${mejora == null ? '' : ' Frente al modelo base (promedio por edad, MAE ${_f(base.mae)} MPa), la curva '
                      '${mejora >= 0 ? 'reduce' : 'aumenta'} el error en ${mejora.abs().toStringAsFixed(1)} %.'}',
              style: text.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Error por edad del ensayo',
            subtitle:
                'Validación cruzada: curva logarítmica vs. promedio por edad',
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
                  DataColumn(label: Text('Edad')),
                  DataColumn(label: Text('n'), numeric: true),
                  DataColumn(label: Text('MAE curva'), numeric: true),
                  DataColumn(label: Text('RMSE curva'), numeric: true),
                  DataColumn(label: Text('MAPE curva'), numeric: true),
                  DataColumn(label: Text('MAE promedio'), numeric: true),
                ],
                rows: [
                  for (final edad in cal.curvaLog.porEdad.keys)
                    DataRow(
                      cells: [
                        DataCell(Text('$edad días')),
                        DataCell(Text('${cal.curvaLog.porEdad[edad]!.n}')),
                        DataCell(Text(_f(cal.curvaLog.porEdad[edad]!.mae))),
                        DataCell(Text(_f(cal.curvaLog.porEdad[edad]!.rmse))),
                        DataCell(
                          Text('${_f(cal.curvaLog.porEdad[edad]!.mape, 1)} %'),
                        ),
                        DataCell(Text(_f(cal.promedioEdad.porEdad[edad]?.mae))),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Historial de calibraciones',
            subtitle: 'MAE de validación después de cada cambio en los ensayos',
            titleStyle: text.titleLarge,
            trailing: FilledButton.tonalIcon(
              onPressed: _running ? null : _recalibrate,
              icon:
                  _running
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Recalibrar'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_history.length >= 2)
            AppCard(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: SizedBox(height: 180, child: _historyChart(theme)),
            ),
          const SizedBox(height: AppSpacing.sm),
          for (final run in _history.reversed.take(8))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.history_rounded),
              title: Text(
                '${_motivos[run.motivo] ?? run.motivo} · ${run.numEnsayos} cilindros',
              ),
              subtitle: Text(
                DateFormat('dd/MM/yyyy HH:mm').format(run.createdAt),
              ),
              trailing: Text(
                '${_f(run.maeValidacion)} MPa',
                style: text.titleSmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _historyChart(ThemeData theme) {
    final scheme = theme.colorScheme;
    final axisStyle = theme.textTheme.labelSmall?.copyWith(letterSpacing: 0);
    final spots = [
      for (final (i, r) in _history.indexed)
        if (r.maeValidacion != null) FlSpot(i.toDouble(), r.maeValidacion!),
    ];
    final ys = spots.map((s) => s.y);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) < 0.02 ? 0.05 : (maxY - minY) * 0.3;

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
          ),
        ],
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
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
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget:
                  (v, meta) =>
                      v == meta.min || v == meta.max
                          ? const SizedBox.shrink()
                          : Text(v.toStringAsFixed(3), style: axisStyle),
            ),
          ),
        ),
      ),
    );
  }
}
