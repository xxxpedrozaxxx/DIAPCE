// lib/services/project_service.dart

import '../core/api_client.dart';
import '../models/project_data.dart';

/// CRUD de proyectos contra `/api/projects`. El servidor filtra por el
/// usuario del token, así que ya no hace falta pasar `userId`.
class ProjectService {
  final ApiClient _api = ApiClient();

  Future<List<ProjectData>> getAllProjects() async {
    final data = await _api.get('/api/projects');
    return (data as List)
        .map((e) => ProjectData.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectData?> getProjectById(int id) async {
    try {
      final data = await _api.get('/api/projects/$id');
      return ProjectData.fromMap(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Crea el proyecto. El servidor calcula las predicciones si no vienen y
  /// genera la mezcla según tipo de estructura y resistencia objetivo
  /// (antes: `saveCompleteProject` + `createRandomExampleMixture`).
  Future<ProjectData> createProject(ProjectData project) async {
    final data = await _api.post('/api/projects', body: _payload(project));
    return ProjectData.fromMap(data as Map<String, dynamic>);
  }

  Future<ProjectData> updateProject(ProjectData project) async {
    final data = await _api.put('/api/projects/${project.id}', body: _payload(project));
    return ProjectData.fromMap(data as Map<String, dynamic>);
  }

  Future<bool> deleteProject(int id) async {
    await _api.delete('/api/projects/$id');
    return true;
  }

  /// Reporte PDF del proyecto (condiciones, predicción, curva y dosificación).
  Future<List<int>> downloadReport(int id) => _api.getBytes('/api/projects/$id/report');

  /// Quita campos que la API marca como `dump_only` y los nulos.
  static Map<String, dynamic> _payload(ProjectData p) {
    final map = p.toMap()
      ..remove('id')
      ..remove('user_id');
    map.removeWhere((_, v) => v == null);
    return map;
  }
}
