// lib/services/project_service.dart

import '../core/database_helper.dart';
import '../models/project_data.dart';

class ProjectService {
  final DatabaseHelper _db = DatabaseHelper();

  // Crear un nuevo proyecto
  Future<int> createProject(ProjectData project) async {
    return await _db.insertProject(project.toMap());
  }

  // Obtener todos los proyectos
  Future<List<ProjectData>> getAllProjects() async {
    final maps = await _db.getProjects();
    return maps.map((map) => ProjectData.fromMap(map)).toList();
  }

  // Obtener un proyecto por ID
  Future<ProjectData?> getProjectById(int id) async {
    final map = await _db.getProjectById(id);
    return map != null ? ProjectData.fromMap(map) : null;
  }

  // Actualizar un proyecto
  Future<bool> updateProject(ProjectData project) async {
    if (project.id == null) return false;
    final result = await _db.updateProject(project.id!, project.toMap());
    return result > 0;
  }

  // Eliminar un proyecto
  Future<bool> deleteProject(int id) async {
    final result = await _db.deleteProject(id);
    return result > 0;
  }

  // Guardar un proyecto completo con su mezcla
  Future<ProjectData?> saveCompleteProject(ProjectData project) async {
    try {
      // Si el proyecto no tiene mixtureId, crear una mezcla de ejemplo
      int? mixtureId = project.mixtureId;
      if (mixtureId == null) {
        mixtureId = await _db.createRandomExampleMixture(project.projectName);
      }

      // Crear el proyecto con el mixtureId
      final projectWithMixture = project.copyWith(mixtureId: mixtureId);
      final projectId = await createProject(projectWithMixture);

      // Actualizar la mezcla para que referencie al proyecto
      await _db.updateMixture(mixtureId, {'project_id': projectId});

      // Retornar el proyecto con su ID asignado
      return projectWithMixture.copyWith(id: projectId);
    } catch (e) {
      print('Error saving complete project: $e');
      return null;
    }
  }
}
