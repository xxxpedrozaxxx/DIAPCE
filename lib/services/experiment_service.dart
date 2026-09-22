// lib/services/experiment_service.dart

import '../core/api_client.dart';

/// Resultado de `/api/experiments/predict`.
class Prediction {
  final double? dias7;
  final double? dias14;
  final double? dias28;
  final int numMuestras;
  final String? formula;
  final double? r2;

  /// Resistencia estimada por la curva f(t) = a + b*ln(t) para varias edades.
  final Map<int, double> curvaEstimada;

  const Prediction({
    this.dias7,
    this.dias14,
    this.dias28,
    required this.numMuestras,
    this.formula,
    this.r2,
    this.curvaEstimada = const {},
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
      curvaEstimada: estimada,
    );
  }
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

/// Rangos de variables que alcanzan una resistencia objetivo.
class OptimalRanges {
  final double objetivo;
  final int totalCombinaciones;
  final int combinacionesQueCumplen;
  final Map<String, List<double>> valores;
  final List<Map<String, dynamic>> mejores;

  const OptimalRanges({
    required this.objetivo,
    required this.totalCombinaciones,
    required this.combinacionesQueCumplen,
    required this.valores,
    required this.mejores,
  });

  factory OptimalRanges.fromMap(Map<String, dynamic> map) {
    final rangos = map['rangos'] as Map<String, dynamic>? ?? {};
    return OptimalRanges(
      objetivo: (map['resistencia_objetivo'] as num).toDouble(),
      totalCombinaciones: map['total_combinaciones'] as int,
      combinacionesQueCumplen: map['combinaciones_que_cumplen'] as int,
      valores: rangos.map(
        (k, v) => MapEntry(
          k,
          ((v as Map<String, dynamic>)['valores'] as List)
              .map((e) => (e as num).toDouble())
              .toList(),
        ),
      ),
      mejores: (map['mejores'] as List).cast<Map<String, dynamic>>(),
    );
  }
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
}
