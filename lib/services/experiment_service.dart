// lib/services/experiment_service.dart

import 'dart:math' as math;

import '../core/api_client.dart';

/// Resultado de `/api/experiments/predict`.
class Prediction {
  final double? dias7;
  final double? dias14;
  final double? dias28;
  final int numMuestras;
  final String? formula;
  final double? r2;

  /// Coeficientes de la curva f(t) = a + b*ln(t) (null si no hay ajuste).
  final double? a;
  final double? b;

  /// Resistencia estimada por la curva f(t) = a + b*ln(t) para varias edades.
  final Map<int, double> curvaEstimada;

  /// Estadística de los ensayos reales por edad (promedio, min, max...).
  final List<AgeStat> porEdad;

  const Prediction({
    this.dias7,
    this.dias14,
    this.dias28,
    required this.numMuestras,
    this.formula,
    this.r2,
    this.a,
    this.b,
    this.curvaEstimada = const {},
    this.porEdad = const [],
  });

  factory Prediction.fromMap(Map<String, dynamic> map) {
    final curva = map['curva'] as Map<String, dynamic>?;
    final estimada = (map['curva_estimada'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
    );
    return Prediction(
      dias7: (map['dias_7'] as num?)?.toDouble(),
      dias14: (map['dias_14'] as num?)?.toDouble(),
      dias28: (map['dias_28'] as num?)?.toDouble(),
      numMuestras: map['num_muestras'] as int? ?? 0,
      formula: curva?['formula'] as String?,
      r2: (curva?['r2'] as num?)?.toDouble(),
      a: (curva?['a'] as num?)?.toDouble(),
      b: (curva?['b'] as num?)?.toDouble(),
      curvaEstimada: estimada,
      porEdad: (map['por_edad'] as List? ?? [])
          .map((e) => AgeStat.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Evalúa la curva ajustada en `t` días (null si no hay curva).
  double? at(double t) => (a == null || b == null || t <= 0) ? null : a! + b! * math.log(t);
}

/// Estadística de ensayos reales para una edad.
class AgeStat {
  final int edadDias;
  final double promedio;
  final double? desviacion;
  final double minimo;
  final double maximo;
  final int numMuestras;

  const AgeStat({
    required this.edadDias,
    required this.promedio,
    this.desviacion,
    required this.minimo,
    required this.maximo,
    required this.numMuestras,
  });

  factory AgeStat.fromMap(Map<String, dynamic> map) => AgeStat(
        edadDias: map['edad_dias'] as int,
        promedio: (map['promedio'] as num).toDouble(),
        desviacion: (map['desviacion'] as num?)?.toDouble(),
        minimo: (map['minimo'] as num).toDouble(),
        maximo: (map['maximo'] as num).toDouble(),
        numMuestras: map['num_muestras'] as int,
      );
}

/// Aditivo disponible para una combinación de condiciones.
class AditivoOption {
  final int id;
  final String codigo;
  final String producto;
  final String porcentaje;
  const AditivoOption({
    required this.id,
    required this.codigo,
    required this.producto,
    required this.porcentaje,
  });

  factory AditivoOption.fromMap(Map<String, dynamic> map) => AditivoOption(
        id: map['id'] as int,
        codigo: map['codigo'] as String,
        producto: map['producto'] as String? ?? '',
        porcentaje: map['porcentaje_aplicado'] as String? ?? '',
      );
}

/// PostgreSQL guarda `timestamp without time zone` con la hora local del
/// servidor; si la fecha trae zona horaria se convierte a la hora local.
DateTime _parseServerDate(String iso) => DateTime.parse(iso).toLocal();

List<double> _doubles(dynamic list) =>
    (list as List? ?? []).map((e) => (e as num).toDouble()).toList();

/// Cantidades de un tipo de aditivo (%) que alcanzan el objetivo.
class AditivoRange {
  final String tipoAditivo;
  final double min;
  final double max;
  final List<double> valores;
  final int combinaciones;

  const AditivoRange({
    required this.tipoAditivo,
    required this.min,
    required this.max,
    required this.valores,
    required this.combinaciones,
  });

  factory AditivoRange.fromMap(Map<String, dynamic> map) => AditivoRange(
        tipoAditivo: map['tipo_aditivo'] as String,
        min: (map['min'] as num).toDouble(),
        max: (map['max'] as num).toDouble(),
        valores: _doubles(map['valores']),
        combinaciones: map['combinaciones'] as int? ?? 0,
      );
}

/// Combinación de condiciones con su resistencia promedio a 28 días.
class Combination {
  final int temperatura;
  final int humedad;
  final double relacionAc;
  final String aditivoCodigo;
  final String tipoAditivo;
  final double porcentajeAditivo;
  final double promedio28d;
  final int numMuestras;

  const Combination({
    required this.temperatura,
    required this.humedad,
    required this.relacionAc,
    required this.aditivoCodigo,
    required this.tipoAditivo,
    required this.porcentajeAditivo,
    required this.promedio28d,
    required this.numMuestras,
  });

  factory Combination.fromMap(Map<String, dynamic> map) => Combination(
        temperatura: map['temperatura'] as int,
        humedad: map['humedad'] as int,
        relacionAc: (map['relacion_ac'] as num).toDouble(),
        aditivoCodigo: map['aditivo_codigo'] as String? ?? '',
        tipoAditivo: map['tipo_aditivo'] as String? ?? '',
        porcentajeAditivo: (map['porcentaje_aditivo'] as num? ?? 0).toDouble(),
        promedio28d: (map['promedio_28d'] as num).toDouble(),
        numMuestras: map['num_muestras'] as int? ?? 0,
      );
}

/// Rangos de variables que alcanzan una resistencia objetivo.
class OptimalRanges {
  final double objetivo;
  final int totalCombinaciones;
  final int combinacionesQueCumplen;

  /// Valores de temperatura, humedad y relacion_ac que alcanzan el objetivo.
  final Map<String, List<double>> valores;

  /// Cantidad de aditivo (%) por tipo de aditivo.
  final List<AditivoRange> aditivos;
  final List<Combination> mejores;

  const OptimalRanges({
    required this.objetivo,
    required this.totalCombinaciones,
    required this.combinacionesQueCumplen,
    required this.valores,
    required this.aditivos,
    required this.mejores,
  });

  factory OptimalRanges.fromMap(Map<String, dynamic> map) {
    final rangos = map['rangos'] as Map<String, dynamic>? ?? {};
    return OptimalRanges(
      objetivo: (map['resistencia_objetivo'] as num).toDouble(),
      totalCombinaciones: map['total_combinaciones'] as int,
      combinacionesQueCumplen: map['combinaciones_que_cumplen'] as int,
      valores: rangos.map(
        (k, v) => MapEntry(k, _doubles((v as Map<String, dynamic>)['valores'])),
      ),
      aditivos: (map['aditivos'] as List? ?? [])
          .map((e) => AditivoRange.fromMap(e as Map<String, dynamic>))
          .toList(),
      mejores: (map['mejores'] as List? ?? [])
          .map((e) => Combination.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Ensayo individual en la gráfica de dispersión.
class DispersionPoint {
  final double x;
  final double y;
  final String tipoAditivo;
  final String aditivoCodigo;

  const DispersionPoint({
    required this.x,
    required this.y,
    required this.tipoAditivo,
    required this.aditivoCodigo,
  });

  factory DispersionPoint.fromMap(Map<String, dynamic> map) => DispersionPoint(
        x: (map['x'] as num).toDouble(),
        y: (map['y'] as num).toDouble(),
        tipoAditivo: map['tipo_aditivo'] as String? ?? '',
        aditivoCodigo: map['aditivo_codigo'] as String? ?? '',
      );
}

/// Fila de la tabla de dispersión: estadística por valor de la variable.
class DispersionRow {
  final double valor;
  final int numMuestras;
  final double promedio;
  final double? desviacion;
  final double? coefVariacion;
  final double minimo;
  final double maximo;
  final double rango;

  const DispersionRow({
    required this.valor,
    required this.numMuestras,
    required this.promedio,
    this.desviacion,
    this.coefVariacion,
    required this.minimo,
    required this.maximo,
    required this.rango,
  });

  factory DispersionRow.fromMap(Map<String, dynamic> map) => DispersionRow(
        valor: (map['valor'] as num).toDouble(),
        numMuestras: map['num_muestras'] as int,
        promedio: (map['promedio'] as num).toDouble(),
        desviacion: (map['desviacion'] as num?)?.toDouble(),
        coefVariacion: (map['coef_variacion'] as num?)?.toDouble(),
        minimo: (map['minimo'] as num).toDouble(),
        maximo: (map['maximo'] as num).toDouble(),
        rango: (map['rango'] as num).toDouble(),
      );
}

/// Resultado de `/api/experiments/dispersion`.
class Dispersion {
  final String variable;
  final int edadDias;
  final int numPuntos;
  final double? correlacion;
  final List<String> tiposAditivo;
  final List<DispersionPoint> puntos;
  final List<DispersionRow> tabla;

  const Dispersion({
    required this.variable,
    required this.edadDias,
    required this.numPuntos,
    this.correlacion,
    required this.tiposAditivo,
    required this.puntos,
    required this.tabla,
  });

  factory Dispersion.fromMap(Map<String, dynamic> map) => Dispersion(
        variable: map['variable'] as String,
        edadDias: map['edad_dias'] as int,
        numPuntos: map['num_puntos'] as int,
        correlacion: (map['correlacion'] as num?)?.toDouble(),
        tiposAditivo: (map['tipos_aditivo'] as List? ?? []).cast<String>(),
        puntos: (map['puntos'] as List? ?? [])
            .map((e) => DispersionPoint.fromMap(e as Map<String, dynamic>))
            .toList(),
        tabla: (map['tabla'] as List? ?? [])
            .map((e) => DispersionRow.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Datos experimentales y modelo matemático (`/api/experiments/*`).
/// Reemplaza `getOpcionesHumedad`, `getOpcionesRelacionAC`,
/// `getAditivosConCodigos` y `getResistenciaPromedio` de DatabaseHelper.
class ExperimentService {
  final ApiClient _api = ApiClient();

  Future<List<int>> getTemperatures() async {
    final data = await _api.get('/api/experiments/options/temperatures');
    return (data as List).cast<int>();
  }

  Future<List<int>> getHumidityOptions(int temperatura) async {
    final data = await _api.get(
      '/api/experiments/options/humidity',
      query: {'temperatura': temperatura},
    );
    return (data as List).cast<int>();
  }

  Future<List<double>> getRelacionAcOptions(int temperatura, int humedad) async {
    final data = await _api.get(
      '/api/experiments/options/relacion-ac',
      query: {'temperatura': temperatura, 'humedad': humedad},
    );
    return (data as List).map((e) => (e as num).toDouble()).toList();
  }

  Future<List<AditivoOption>> getAditivoOptions(
    int temperatura,
    int humedad,
    double relacionAc,
  ) async {
    final data = await _api.get(
      '/api/experiments/options/aditivos',
      query: {'temperatura': temperatura, 'humedad': humedad, 'relacion_ac': relacionAc},
    );
    return (data as List)
        .map((e) => AditivoOption.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Prediction> predict({
    required int temperatura,
    required int humedad,
    required double relacionAc,
    int aditivoId = 1,
  }) async {
    final data = await _api.get('/api/experiments/predict', query: {
      'temperatura': temperatura,
      'humedad': humedad,
      'relacion_ac': relacionAc,
      'aditivo_id': aditivoId,
    });
    return Prediction.fromMap(data as Map<String, dynamic>);
  }

  /// `tipoEstructura`: Puentes | Tuneles | Muros | sin_clasificar (null = todas).
  Future<OptimalRanges> optimalRanges(double resistenciaObjetivo, {String? tipoEstructura}) async {
    final data = await _api.get('/api/experiments/optimal-ranges', query: {
      'resistencia_objetivo': resistenciaObjetivo,
      if (tipoEstructura != null) 'tipo_estructura': tipoEstructura,
    });
    return OptimalRanges.fromMap(data as Map<String, dynamic>);
  }

  /// `variable`: temperatura | humedad | relacion_ac | porcentaje_aditivo.
  Future<Dispersion> dispersion({
    required String variable,
    int edadDias = 28,
    String? tipoAditivo,
    String? tipoEstructura,
  }) async {
    final data = await _api.get('/api/experiments/dispersion', query: {
      'variable': variable,
      'edad_dias': edadDias,
      if (tipoAditivo != null) 'tipo_aditivo': tipoAditivo,
      if (tipoEstructura != null) 'tipo_estructura': tipoEstructura,
    });
    return Dispersion.fromMap(data as Map<String, dynamic>);
  }

  // ── Estadística inferencial y optimización ───────────────────────────

  Future<Anova> anova({int edadDias = 28}) async {
    final data = await _api.get('/api/experiments/anova', query: {'edad_dias': edadDias});
    return Anova.fromMap(data as Map<String, dynamic>);
  }

  Future<RegressionModel> regressionModel() async {
    final data = await _api.get('/api/experiments/model');
    return RegressionModel.fromMap(data as Map<String, dynamic>);
  }

  /// Dosificación de menor contenido de cemento que alcanza f'cr en el clima de la obra.
  Future<Optimization> optimize({
    required double resistenciaObjetivo,
    required double temperatura,
    required double humedad,
    required String tipoEstructura,
  }) async {
    final data = await _api.post('/api/experiments/optimize', body: {
      'resistencia_objetivo': resistenciaObjetivo,
      'temperatura': temperatura,
      'humedad': humedad,
      'tipo_estructura': tipoEstructura,
    });
    return Optimization.fromMap(data as Map<String, dynamic>);
  }

  // ── Calibración ──────────────────────────────────────────────────────

  Future<Calibration> calibration() async {
    final data = await _api.get('/api/experiments/calibration');
    return Calibration.fromMap(data as Map<String, dynamic>);
  }

  Future<List<CalibrationRun>> calibrationHistory() async {
    final data = await _api.get('/api/experiments/calibration/history');
    return (data as List)
        .map((e) => CalibrationRun.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<CalibrationRun> runCalibration() async {
    final data = await _api.post('/api/experiments/calibration/run');
    return CalibrationRun.fromMap(data as Map<String, dynamic>);
  }

  // ── Registro de ensayos ──────────────────────────────────────────────

  Future<ResultadoPage> listResults({
    String? tipoEstructura,
    String? origen,
    int page = 1,
    int perPage = 30,
  }) async {
    final data = await _api.get('/api/experiments/results', query: {
      if (tipoEstructura != null) 'tipo_estructura': tipoEstructura,
      if (origen != null) 'origen': origen,
      'page': page,
      'per_page': perPage,
    });
    return ResultadoPage.fromMap(data as Map<String, dynamic>);
  }

  Future<Resultado> registerResult(Map<String, dynamic> ensayo) async {
    final data = await _api.post('/api/experiments/results', body: ensayo);
    return Resultado.fromMap(data as Map<String, dynamic>);
  }

  Future<void> deleteResult(int id) => _api.delete('/api/experiments/results/$id');

  /// Importa ensayos desde texto CSV. Si alguna línea falla lanza
  /// [ImportException] con las líneas y sus errores (no se guarda nada).
  Future<int> importCsv(String csv) async {
    try {
      final data = await _api.post('/api/experiments/results/import', body: {'csv': csv});
      return (data as Map<String, dynamic>)['insertados'] as int;
    } on ApiException catch (e) {
      final body = e.body;
      if (e.statusCode == 422 && body is Map && body['errores'] is List) {
        throw ImportException((body['errores'] as List)
            .map((x) => ImportError.fromMap(x as Map<String, dynamic>))
            .toList());
      }
      rethrow;
    }
  }

  Future<List<AditivoCatalogo>> aditivos() async {
    final data = await _api.get('/api/catalog/aditivos');
    return (data as List)
        .map((e) => AditivoCatalogo.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Modelos de calibración ─────────────────────────────────────────────

/// Error de un modelo (MAE, RMSE, MAPE) sobre `n` cilindros.
class ErrorMetrics {
  final int n;
  final double? mae;
  final double? rmse;
  final double? mape;

  const ErrorMetrics({required this.n, this.mae, this.rmse, this.mape});

  factory ErrorMetrics.fromMap(Map<String, dynamic> map) => ErrorMetrics(
        n: map['n'] as int? ?? 0,
        mae: (map['mae'] as num?)?.toDouble(),
        rmse: (map['rmse'] as num?)?.toDouble(),
        mape: (map['mape'] as num?)?.toDouble(),
      );
}

/// Validación cruzada de un modelo: global y por edad del ensayo.
class ModelValidation {
  final ErrorMetrics global;
  final Map<int, ErrorMetrics> porEdad;

  const ModelValidation({required this.global, required this.porEdad});

  factory ModelValidation.fromMap(Map<String, dynamic> map) => ModelValidation(
        global: ErrorMetrics.fromMap(map),
        porEdad: {
          for (final e in (map['por_edad'] as List? ?? []).cast<Map<String, dynamic>>())
            e['edad_dias'] as int: ErrorMetrics.fromMap(e),
        },
      );
}

/// Resultado de `/api/experiments/calibration`.
class Calibration {
  final int numEnsayos;
  final int combinaciones;
  final double maeAjuste;
  final double rmseAjuste;
  final double? r2Promedio;

  /// Curva f(t) = a + b·ln(t) y modelo base (promedio por edad) evaluados
  /// dejando un cilindro fuera.
  final ModelValidation curvaLog;
  final ModelValidation promedioEdad;

  const Calibration({
    required this.numEnsayos,
    required this.combinaciones,
    required this.maeAjuste,
    required this.rmseAjuste,
    this.r2Promedio,
    required this.curvaLog,
    required this.promedioEdad,
  });

  factory Calibration.fromMap(Map<String, dynamic> map) {
    final val = map['validacion'] as Map<String, dynamic>;
    return Calibration(
      numEnsayos: map['num_ensayos'] as int,
      combinaciones: map['combinaciones'] as int,
      maeAjuste: (map['mae_global'] as num).toDouble(),
      rmseAjuste: (map['rmse_global'] as num).toDouble(),
      r2Promedio: (map['r2_promedio'] as num?)?.toDouble(),
      curvaLog: ModelValidation.fromMap(val['curva_log'] as Map<String, dynamic>),
      promedioEdad: ModelValidation.fromMap(val['promedio_edad'] as Map<String, dynamic>),
    );
  }
}

/// Una ejecución guardada en el historial de calibración.
class CalibrationRun {
  final int id;
  final DateTime createdAt;
  final String motivo;
  final int numEnsayos;
  final double maeAjuste;
  final double? maeValidacion;
  final double? rmseValidacion;
  final double? mapeValidacion;

  const CalibrationRun({
    required this.id,
    required this.createdAt,
    required this.motivo,
    required this.numEnsayos,
    required this.maeAjuste,
    this.maeValidacion,
    this.rmseValidacion,
    this.mapeValidacion,
  });

  factory CalibrationRun.fromMap(Map<String, dynamic> map) => CalibrationRun(
        id: map['id'] as int,
        createdAt: _parseServerDate(map['created_at'] as String),
        motivo: map['motivo'] as String,
        numEnsayos: map['num_ensayos'] as int,
        maeAjuste: (map['mae_ajuste'] as num).toDouble(),
        maeValidacion: (map['mae_validacion'] as num?)?.toDouble(),
        rmseValidacion: (map['rmse_validacion'] as num?)?.toDouble(),
        mapeValidacion: (map['mape_validacion'] as num?)?.toDouble(),
      );
}

// ── Modelos de registro de ensayos ─────────────────────────────────────

/// Ensayo de compresión de un cilindro.
class Resultado {
  final int id;
  final int temperatura;
  final int humedad;
  final double relacionAc;
  final int edadDias;
  final double resistenciaMpa;
  final String aditivoCodigo;
  final String? tipoEstructura;
  final String origen;
  final DateTime? fechaEnsayo;
  final String? observaciones;

  const Resultado({
    required this.id,
    required this.temperatura,
    required this.humedad,
    required this.relacionAc,
    required this.edadDias,
    required this.resistenciaMpa,
    required this.aditivoCodigo,
    this.tipoEstructura,
    required this.origen,
    this.fechaEnsayo,
    this.observaciones,
  });

  factory Resultado.fromMap(Map<String, dynamic> map) => Resultado(
        id: map['id'] as int,
        temperatura: map['temperatura'] as int,
        humedad: map['humedad'] as int,
        relacionAc: (map['relacion_ac'] as num).toDouble(),
        edadDias: map['edad_dias'] as int,
        resistenciaMpa: (map['resistencia_mpa'] as num).toDouble(),
        aditivoCodigo: map['aditivo_codigo'] as String? ?? '',
        tipoEstructura: map['tipo_estructura'] as String?,
        origen: map['origen'] as String? ?? 'semilla',
        fechaEnsayo: map['fecha_ensayo'] == null
            ? null
            : DateTime.parse(map['fecha_ensayo'] as String),
        observaciones: map['observaciones'] as String?,
      );
}

class ResultadoPage {
  final int total;
  final int page;
  final int perPage;
  final List<Resultado> items;

  const ResultadoPage({
    required this.total,
    required this.page,
    required this.perPage,
    required this.items,
  });

  bool get hasMore => page * perPage < total;

  factory ResultadoPage.fromMap(Map<String, dynamic> map) => ResultadoPage(
        total: map['total'] as int,
        page: map['page'] as int,
        perPage: map['per_page'] as int,
        items: (map['items'] as List)
            .map((e) => Resultado.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
}

class ImportError {
  final int linea;
  final String mensaje;
  const ImportError(this.linea, this.mensaje);

  factory ImportError.fromMap(Map<String, dynamic> map) =>
      ImportError(map['linea'] as int, map['mensaje'] as String);
}

class ImportException implements Exception {
  final List<ImportError> errores;
  const ImportException(this.errores);
}

/// Aditivo del catálogo completo (`/api/catalog/aditivos`).
class AditivoCatalogo {
  final int id;
  final String codigo;
  final String porcentaje;
  final String tipo;
  final String producto;

  const AditivoCatalogo({
    required this.id,
    required this.codigo,
    required this.porcentaje,
    required this.tipo,
    required this.producto,
  });

  factory AditivoCatalogo.fromMap(Map<String, dynamic> map) => AditivoCatalogo(
        id: map['id'] as int,
        codigo: map['codigo'] as String,
        porcentaje: map['porcentaje_aplicado'] as String? ?? '',
        tipo: map['tipo_aditivo'] as String? ?? '',
        producto: map['producto'] as String? ?? '',
      );
}

// ── Modelos de estadística inferencial y optimización ──────────────────

/// Fila de la tabla ANOVA.
class AnovaRow {
  final String fuente;
  final double sc;
  final int gl;
  final double? f;
  final double? p;
  final double eta2Parcial;

  const AnovaRow({
    required this.fuente,
    required this.sc,
    required this.gl,
    this.f,
    this.p,
    required this.eta2Parcial,
  });

  factory AnovaRow.fromMap(Map<String, dynamic> map) => AnovaRow(
        fuente: map['fuente'] as String,
        sc: (map['sc'] as num).toDouble(),
        gl: map['gl'] as int,
        f: (map['f'] as num?)?.toDouble(),
        p: (map['p'] as num?)?.toDouble(),
        eta2Parcial: (map['eta2_parcial'] as num).toDouble(),
      );

  bool get significativo => (p ?? 1) < 0.05;
}

/// Resultado de `/api/experiments/anova`.
class Anova {
  final int edadDias;
  final int n;
  final double r2;
  final List<AnovaRow> filas;
  final int glResidual;
  final double cmResidual;

  const Anova({
    required this.edadDias,
    required this.n,
    required this.r2,
    required this.filas,
    required this.glResidual,
    required this.cmResidual,
  });

  factory Anova.fromMap(Map<String, dynamic> map) {
    final residual = map['residual'] as Map<String, dynamic>;
    return Anova(
      edadDias: map['edad_dias'] as int,
      n: map['n'] as int,
      r2: (map['r2'] as num).toDouble(),
      filas: (map['filas'] as List).map((e) => AnovaRow.fromMap(e as Map<String, dynamic>)).toList(),
      glResidual: residual['gl'] as int,
      cmResidual: (residual['cm'] as num).toDouble(),
    );
  }
}

/// Resultado de `/api/experiments/model` (regresión múltiple).
class RegressionModel {
  final String ecuacion;
  final double r2;
  final double r2Ajustado;
  final double rmse;
  final ErrorMetrics validacion;

  const RegressionModel({
    required this.ecuacion,
    required this.r2,
    required this.r2Ajustado,
    required this.rmse,
    required this.validacion,
  });

  factory RegressionModel.fromMap(Map<String, dynamic> map) => RegressionModel(
        ecuacion: map['ecuacion'] as String,
        r2: (map['r2'] as num).toDouble(),
        r2Ajustado: (map['r2_ajustado'] as num).toDouble(),
        rmse: (map['rmse'] as num).toDouble(),
        validacion: ErrorMetrics.fromMap(map['validacion'] as Map<String, dynamic>),
      );
}

class MixComponent {
  final String nombre;
  final String unidad;
  final double cantidad;
  const MixComponent(this.nombre, this.unidad, this.cantidad);

  factory MixComponent.fromMap(Map<String, dynamic> map) => MixComponent(
        map['nombre'] as String,
        map['unidad'] as String,
        (map['cantidad'] as num).toDouble(),
      );
}

/// Una alternativa de dosificación (un aditivo con su a/c óptima).
class OptimizationAlternative {
  final String aditivoCodigo;
  final String tipoAditivo;
  final double dosisPct;
  final double relacionAc;
  final double prediccion;
  final double margen;
  final bool factible;
  final double cemento;
  final double? costoReferencia;
  final List<MixComponent> materiales;
  final String descripcion;

  const OptimizationAlternative({
    required this.aditivoCodigo,
    required this.tipoAditivo,
    required this.dosisPct,
    required this.relacionAc,
    required this.prediccion,
    required this.margen,
    required this.factible,
    required this.cemento,
    this.costoReferencia,
    required this.materiales,
    required this.descripcion,
  });

  factory OptimizationAlternative.fromMap(Map<String, dynamic> map) => OptimizationAlternative(
        aditivoCodigo: map['aditivo_codigo'] as String,
        tipoAditivo: map['tipo_aditivo'] as String,
        dosisPct: (map['dosis_pct'] as num).toDouble(),
        relacionAc: (map['relacion_ac'] as num).toDouble(),
        prediccion: (map['prediccion'] as num).toDouble(),
        margen: (map['margen'] as num).toDouble(),
        factible: map['factible'] as bool,
        cemento: (map['cemento'] as num).toDouble(),
        costoReferencia: (map['costo_referencia'] as num?)?.toDouble(),
        materiales: (map['materiales'] as List)
            .map((e) => MixComponent.fromMap(e as Map<String, dynamic>))
            .toList(),
        descripcion: map['descripcion'] as String? ?? '',
      );
}

/// Resultado de `/api/experiments/optimize`.
class Optimization {
  final double resistenciaEspecificada;
  final double resistenciaRequerida;
  final double desviacionEstandar;
  final List<String> advertencias;
  final List<OptimizationAlternative> alternativas;

  const Optimization({
    required this.resistenciaEspecificada,
    required this.resistenciaRequerida,
    required this.desviacionEstandar,
    required this.advertencias,
    required this.alternativas,
  });

  OptimizationAlternative? get mejor =>
      alternativas.isNotEmpty && alternativas.first.factible ? alternativas.first : null;

  factory Optimization.fromMap(Map<String, dynamic> map) => Optimization(
        resistenciaEspecificada: (map['resistencia_especificada'] as num).toDouble(),
        resistenciaRequerida: (map['resistencia_requerida'] as num).toDouble(),
        desviacionEstandar: (map['desviacion_estandar'] as num).toDouble(),
        advertencias: (map['advertencias'] as List).cast<String>(),
        alternativas: (map['alternativas'] as List)
            .map((e) => OptimizationAlternative.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
}
