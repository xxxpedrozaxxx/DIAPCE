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
  final double minimo;
  final double maximo;
  final int numMuestras;

  const AgeStat({
    required this.edadDias,
    required this.promedio,
    required this.minimo,
    required this.maximo,
    required this.numMuestras,
  });

  factory AgeStat.fromMap(Map<String, dynamic> map) => AgeStat(
        edadDias: map['edad_dias'] as int,
        promedio: (map['promedio'] as num).toDouble(),
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

  Future<OptimalRanges> optimalRanges(double resistenciaObjetivo) async {
    final data = await _api.get(
      '/api/experiments/optimal-ranges',
      query: {'resistencia_objetivo': resistenciaObjetivo},
    );
    return OptimalRanges.fromMap(data as Map<String, dynamic>);
  }

  /// `variable`: temperatura | humedad | relacion_ac | porcentaje_aditivo.
  Future<Dispersion> dispersion({
    required String variable,
    int edadDias = 28,
    String? tipoAditivo,
  }) async {
    final data = await _api.get('/api/experiments/dispersion', query: {
      'variable': variable,
      'edad_dias': edadDias,
      if (tipoAditivo != null) 'tipo_aditivo': tipoAditivo,
    });
    return Dispersion.fromMap(data as Map<String, dynamic>);
  }
}
