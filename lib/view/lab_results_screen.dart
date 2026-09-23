// lib/view/lab_results_screen.dart
//
// Registro de ensayos de laboratorio: lista paginada de cilindros ensayados,
// filtrada por tipo de estructura, con alta individual, importación por lote
// desde CSV y eliminación de ensayos mal digitados.
import 'package:diapce_aplicationn/components/app_card.dart';
import 'package:diapce_aplicationn/components/app_choice_chips.dart';
import 'package:diapce_aplicationn/components/empty_state.dart';
import 'package:diapce_aplicationn/core/api_client.dart';
import 'package:diapce_aplicationn/core/estructuras.dart';
import 'package:diapce_aplicationn/core/theme/app_spacing.dart';
import 'package:diapce_aplicationn/services/experiment_service.dart';
import 'package:diapce_aplicationn/view/register_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _plantillaCsv =
    'temperatura;humedad;relacion_ac;edad_dias;resistencia_mpa;aditivo;tipo_estructura;fecha_ensayo\n'
    '30;85;0,45;7;29,8;P2;Tuneles;2026-09-01\n'
    '30;85;0,45;28;45,1;P2;Tuneles;2026-09-22';

class LabResultsScreen extends StatefulWidget {
  const LabResultsScreen({super.key});

  @override
  State<LabResultsScreen> createState() => _LabResultsScreenState();
}

class _LabResultsScreenState extends State<LabResultsScreen> {
  final ExperimentService _experiments = ExperimentService();

  /// null = todas; 'sin_clasificar' = ensayos históricos sin estructura.
  String? _estructura;
  final List<Resultado> _items = [];
  int _total = 0;
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (reset) _page = 1;
    });
    try {
      final page = await _experiments.listResults(
        tipoEstructura: _estructura,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(page.items);
        _total = page.total;
        _hasMore = page.hasMore;
        _page = page.page + 1;
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

  void _snack(String message, {bool error = false}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? scheme.error : null,
      ),
    );
  }

  Future<void> _register() async {
    final registrados = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterResultScreen()),
    );
    if (registrados != null && registrados > 0) _load(reset: true);
  }

  Future<void> _delete(Resultado r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar ensayo'),
            content: Text(
              '¿Eliminar el cilindro de ${r.resistenciaMpa.toStringAsFixed(1)} MPa '
              '(${r.edadDias} días)? El modelo se recalibrará sin este dato.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    if (ok != true) return;
    try {
      await _experiments.deleteResult(r.id);
      if (!mounted) return;
      setState(() {
        _items.removeWhere((x) => x.id == r.id);
        _total--;
      });
      _snack('Ensayo eliminado. Modelo recalibrado.');
    } on ApiException catch (e) {
      if (!mounted) return;
      _snack(
        e.statusCode == 404
            ? 'Solo puedes eliminar ensayos que registraste tú.'
            : e.message,
        error: true,
      );
    }
  }

  Future<void> _import() async {
    final insertados = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ImportSheet(),
    );
    if (insertados != null && mounted) {
      _snack('$insertados ensayos importados. Modelo recalibrado.');
      _load(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ensayos de laboratorio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'Importar CSV',
            onPressed: _import,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _register,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Registrar ensayo'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl * 2,
          ),
          children: [
            Text(
              '$_total ${_total == 1 ? 'cilindro ensayado' : 'cilindros ensayados'}',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            AppChoiceChips<String?>(
              options: filtrosEstructura,
              selected: _estructura,
              labelBuilder: filtroEstructuraLabel,
              onSelected: (e) {
                setState(() => _estructura = e);
                _load(reset: true);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_loading && _items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _items.isEmpty)
              EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Sin conexión',
                message: _error,
              )
            else if (_items.isEmpty)
              EmptyState(
                icon: Icons.science_outlined,
                title: 'Aún no hay ensayos',
                message:
                    'Registra el primer cilindro o importa un CSV con los resultados del laboratorio.',
                action: FilledButton.icon(
                  onPressed: _register,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Registrar ensayo'),
                ),
              )
            else ...[
              for (final r in _items) ...[
                _ResultTile(
                  result: r,
                  onDelete: r.origen == 'semilla' ? null : () => _delete(r),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (_hasMore)
                Center(
                  child:
                      _loading
                          ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: CircularProgressIndicator(),
                          )
                          : TextButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.expand_more_rounded),
                            label: const Text('Cargar más'),
                          ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Resultado result;
  final VoidCallback? onDelete;

  const _ResultTile({required this.result, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final r = result;
    final origen = switch (r.origen) {
      'registro' => 'Registrado',
      'importacion' => 'Importado',
      _ => 'Histórico',
    };
    final fecha =
        r.fechaEnsayo == null
            ? ''
            : ' · ${DateFormat('dd/MM/yyyy').format(r.fechaEnsayo!)}';

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      onLongPress: onDelete,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: AppRadius.baseAll,
            ),
            alignment: Alignment.center,
            child: Text(
              '${r.edadDias}d',
              style: text.labelLarge?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r.temperatura} °C · ${r.humedad} % · a/c ${r.relacionAc.toStringAsFixed(2)} · ${r.aditivoCodigo}',
                  style: text.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${estructuraLabel(r.tipoEstructura)} · $origen$fecha',
                  style: text.bodySmall,
                ),
                if (r.observaciones != null)
                  Text(
                    r.observaciones!,
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            r.resistenciaMpa.toStringAsFixed(1),
            style: text.titleLarge?.copyWith(color: scheme.primary),
          ),
          const SizedBox(width: 2),
          Text('MPa', style: text.labelSmall),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              tooltip: 'Eliminar',
              onPressed: onDelete,
            )
          else
            const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}

/// Hoja inferior para pegar el contenido de un CSV y enviarlo al servidor.
class _ImportSheet extends StatefulWidget {
  const _ImportSheet();

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  final ExperimentService _experiments = ExperimentService();
  final _csv = TextEditingController();
  List<ImportError> _errores = [];
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _csv.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _errores = [];
      _error = null;
    });
    try {
      final n = await _experiments.importCsv(_csv.text);
      if (mounted) Navigator.pop(context, n);
    } on ImportException catch (e) {
      setState(() {
        _errores = e.errores;
        _sending = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Importar ensayos (CSV)', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pega el contenido del archivo con encabezado. Separador ; o , — aditivo por código '
              '(P0…PP3) y estructura Puentes, Tuneles o Muros. Si una línea tiene errores no se '
              'guarda ninguna.',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _csv,
              minLines: 6,
              maxLines: 12,
              style: text.bodySmall?.copyWith(fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: _plantillaCsv,
                alignLabelWithHint: true,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _csv.text = _plantillaCsv),
                child: const Text('Usar plantilla de ejemplo'),
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: text.bodySmall?.copyWith(color: scheme.error),
              ),
            if (_errores.isNotEmpty) ...[
              Text(
                '${_errores.length} ${_errores.length == 1 ? 'línea con errores' : 'líneas con errores'} — no se importó nada:',
                style: text.labelLarge?.copyWith(color: scheme.error),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final e in _errores.take(8))
                Text('Línea ${e.linea}: ${e.mensaje}', style: text.bodySmall),
              if (_errores.length > 8) Text('…', style: text.bodySmall),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sending ? null : _send,
                icon:
                    _sending
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.upload_rounded),
                label: const Text('Importar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
