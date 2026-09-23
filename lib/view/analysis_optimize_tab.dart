// lib/view/analysis_optimize_tab.dart
//
// Optimización de la dosificación: dado el clima de la obra, el tipo de
// estructura y la resistencia especificada f'c, el servidor usa el modelo de
// regresión múltiple para encontrar la relación a/c y el aditivo que alcanzan
// la resistencia promedio requerida f'cr (ACI 318) con el menor contenido de
// cemento, y dosifica cada alternativa por ACI 211.1.
import 'package:diapce_aplicationn/components/app_button.dart';
import 'package:diapce_aplicationn/components/app_card.dart';
import 'package:diapce_aplicationn/components/app_choice_chips.dart';
import 'package:diapce_aplicationn/components/section_header.dart';
import 'package:diapce_aplicationn/components/stat_tile.dart';
import 'package:diapce_aplicationn/core/api_client.dart';
import 'package:diapce_aplicationn/core/estructuras.dart';
import 'package:diapce_aplicationn/core/theme/app_spacing.dart';
import 'package:diapce_aplicationn/services/experiment_service.dart';
import 'package:flutter/material.dart';

String _n(double v, [int d = 1]) => v.toStringAsFixed(d).replaceAll('.', ',');

class OptimizeTab extends StatefulWidget {
  const OptimizeTab({super.key});

  @override
  State<OptimizeTab> createState() => _OptimizeTabState();
}

class _OptimizeTabState extends State<OptimizeTab>
    with AutomaticKeepAliveClientMixin {
  final ExperimentService _experiments = ExperimentService();

  double _fc = 28;
  double _temperatura = 27;
  double _humedad = 70;
  String _estructura = 'Puentes';
  RegressionModel? _modelo;
  Optimization? _resultado;
  bool _loading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _experiments
        .regressionModel()
        .then((m) {
          if (mounted) setState(() => _modelo = m);
        })
        .catchError((_) {});
  }

  Future<void> _optimizar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _experiments.optimize(
        resistenciaObjetivo: _fc,
        temperatura: _temperatura,
        humedad: _humedad,
        tipoEstructura: _estructura,
      );
      if (mounted) setState(() => _resultado = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final r = _resultado;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        const SectionHeader(
          eyebrow: 'Modelo de regresión múltiple',
          title: 'Optimizar la dosificación',
          subtitle:
              'Menor contenido de cemento que alcanza la resistencia requerida en el clima de la obra.',
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SliderRow(
                label: "Resistencia especificada f'c",
                value: '${_n(_fc, 0)} MPa',
                child: Slider(
                  value: _fc,
                  min: 21,
                  max: 55,
                  divisions: 34,
                  onChanged: (v) => setState(() => _fc = v),
                ),
              ),
              _SliderRow(
                label: 'Temperatura de la obra',
                value: '${_n(_temperatura, 0)} °C',
                caption: 'Rango ensayado: 10–32 °C',
                child: Slider(
                  value: _temperatura,
                  min: 5,
                  max: 40,
                  divisions: 35,
                  onChanged: (v) => setState(() => _temperatura = v),
                ),
              ),
              _SliderRow(
                label: 'Humedad relativa de la obra',
                value: '${_n(_humedad, 0)} %',
                caption: 'Rango ensayado: 20–70 %',
                child: Slider(
                  value: _humedad,
                  min: 10,
                  max: 100,
                  divisions: 18,
                  onChanged: (v) => setState(() => _humedad = v),
                ),
              ),
              Text('Tipo de estructura', style: text.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              AppChoiceChips<String>(
                options: estructuras.map((e) => e.$1).toList(),
                selected: _estructura,
                labelBuilder: estructuraLabel,
                onSelected: (e) => setState(() => _estructura = e),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Optimizar',
                icon: Icons.auto_fix_high_rounded,
                loading: _loading,
                onPressed: _optimizar,
              ),
            ],
          ),
        ),
        if (_modelo != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Modelo: R² ${_n(_modelo!.r2, 3)} · error en combinaciones no ensayadas (validación cruzada) '
            'MAE ${_n(_modelo!.validacion.mae ?? 0, 2)} MPa.',
            style: text.bodySmall,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: text.bodySmall?.copyWith(color: scheme.error)),
        ],
        if (r != null) ...[
          const SizedBox(height: AppSpacing.lg),
          for (final a in r.advertencias)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                color: scheme.errorContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: scheme.onErrorContainer,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        a,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: "f'c",
                  value: _n(r.resistenciaEspecificada, 0),
                  unit: 'MPa',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  label: 'Desv. s',
                  value: _n(r.desviacionEstandar, 2),
                  unit: 'MPa',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  label: "f'cr",
                  value: _n(r.resistenciaRequerida),
                  unit: 'MPa',
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "f'cr es la resistencia promedio requerida por ACI 318 para que la resistencia especificada se cumpla "
            'con la variabilidad observada en el laboratorio (s).',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (r.mejor != null) _Recomendacion(alt: r.mejor!),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Alternativas por aditivo',
            subtitle:
                'Mayor a/c que alcanza f\'cr con cada aditivo (a/c limitada a 0,40–0,50)',
            titleStyle: text.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 40,
                headingTextStyle: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                columns: const [
                  DataColumn(label: Text('Aditivo')),
                  DataColumn(label: Text('a/c'), numeric: true),
                  DataColumn(label: Text("f'c pred."), numeric: true),
                  DataColumn(label: Text('Cumple')),
                  DataColumn(label: Text('Cemento'), numeric: true),
                ],
                rows: [
                  for (final a in r.alternativas)
                    DataRow(
                      cells: [
                        DataCell(
                          Text(
                            a.dosisPct == 0
                                ? '${a.aditivoCodigo} · control'
                                : '${a.aditivoCodigo} · ${a.tipoAditivo.substring(0, 5)}. ${_n(a.dosisPct)} %',
                          ),
                        ),
                        DataCell(Text(_n(a.relacionAc, 2))),
                        DataCell(Text(_n(a.prediccion))),
                        DataCell(
                          Icon(
                            a.factible
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            size: 18,
                            color: a.factible ? Colors.green : scheme.error,
                          ),
                        ),
                        DataCell(Text('${_n(a.cemento, 0)} kg')),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Recomendacion extends StatelessWidget {
  final OptimizationAlternative alt;
  const _Recomendacion({required this.alt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final aditivo =
        alt.dosisPct == 0
            ? 'sin aditivo'
            : '${alt.aditivoCodigo} (${alt.tipoAditivo.toLowerCase()} ${_n(alt.dosisPct)} %)';

    return AppCard(
      color: scheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECOMENDACIÓN',
            style: text.labelSmall?.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'a/c ${_n(alt.relacionAc, 2)} · $aditivo',
            style: text.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Resistencia estimada ${_n(alt.prediccion)} MPa (margen +${_n(alt.margen)} MPa sobre f'cr) · "
            'cemento ${_n(alt.cemento, 0)} kg/m³',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final m in alt.materiales)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Text(m.nombre, style: text.bodyMedium)),
                  Text('${_n(m.cantidad)} ${m.unidad}', style: text.titleSmall),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(alt.descripcion, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final Widget child;

  const _SliderRow({
    required this.label,
    required this.value,
    this.caption,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: text.labelLarge)),
            Text(
              value,
              style: text.titleMedium?.copyWith(color: scheme.primary),
            ),
          ],
        ),
        if (caption != null) Text(caption!, style: text.bodySmall),
        child,
      ],
    );
  }
}
