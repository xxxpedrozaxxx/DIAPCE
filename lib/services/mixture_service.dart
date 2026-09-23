// lib/services/mixture_service.dart

import '../core/api_client.dart';
import '../models/mixture.dart';

/// Mezclas contra `/api/mixtures`. La composición (materiales) viene
/// incluida en la respuesta del detalle.
class MixtureService {
  final ApiClient _api = ApiClient();

  Future<Mixture?> getMixtureWithMaterials(int id) async {
    try {
      final data = await _api.get('/api/mixtures/$id') as Map<String, dynamic>;
      return _withMaterials(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Dosificación ACI 211.1 que el servidor asignaría a un proyecto nuevo
  /// (sin guardar), según la relación a/c, el aditivo y el tipo de estructura.
  Future<Mixture> previewMixture(String workType, double relacionAc, int? aditivoId) async {
    final data = await _api.get(
      '/api/mixtures/preview',
      query: {
        'work_type': workType,
        'relacion_ac': relacionAc,
        if (aditivoId != null) 'aditivo_id': aditivoId,
      },
    );
    return _withMaterials(data as Map<String, dynamic>);
  }

  Future<List<MaterialInMixture>> getMaterialsInMixture(int mixtureId) async =>
      (await getMixtureWithMaterials(mixtureId))?.materials ?? [];

  Future<Mixture> addMaterialToMixture(int mixtureId, int materialId, double quantity) async {
    final data = await _api.post(
      '/api/mixtures/$mixtureId/materials',
      body: {'material_id': materialId, 'quantity': quantity},
    );
    return _withMaterials(data as Map<String, dynamic>);
  }

  Future<Mixture> removeMaterialFromMixture(int mixtureId, int materialId) async {
    final data = await _api.delete('/api/mixtures/$mixtureId/materials/$materialId');
    return _withMaterials(data as Map<String, dynamic>);
  }

  Future<Map<String, double>> getMixtureStatistics(int mixtureId) async {
    final data = await _api.get('/api/mixtures/$mixtureId/statistics') as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<double> calculateMixtureCost(int mixtureId) async =>
      (await getMixtureStatistics(mixtureId))['totalCost'] ?? 0.0;

  static Mixture _withMaterials(Map<String, dynamic> data) {
    final materials = (data['materials'] as List? ?? [])
        .map((e) => MaterialInMixture.fromMap(e as Map<String, dynamic>))
        .toList();
    return Mixture.fromMap(data).copyWith(materials: materials);
  }
}
