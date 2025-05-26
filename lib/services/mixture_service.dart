// lib/services/mixture_service.dart

import '../core/database_helper.dart';
import '../models/material.dart';
import '../models/mixture.dart';

class MixtureService {
  final DatabaseHelper _db = DatabaseHelper();

  // === MATERIALES ===
  Future<List<Material>> getAllMaterials() async {
    final maps = await _db.getMaterials();
    return maps.map((map) => Material.fromMap(map)).toList();
  }

  Future<Material?> getMaterialById(int id) async {
    final map = await _db.getMaterialById(id);
    return map != null ? Material.fromMap(map) : null;
  }

  Future<int> createMaterial(Material material) async {
    return await _db.insertMaterial(material.toMap());
  }

  Future<bool> updateMaterial(Material material) async {
    final result = await _db.updateMaterial(material.id!, material.toMap());
    return result > 0;
  }

  Future<bool> deleteMaterial(int id) async {
    final result = await _db.deleteMaterial(id);
    return result > 0;
  }

  // === MEZCLAS ===
  Future<List<Mixture>> getAllMixtures() async {
    final maps = await _db.getMixtures();
    return maps.map((map) => Mixture.fromMap(map)).toList();
  }

  Future<List<Mixture>> getMixturesByProject(int projectId) async {
    final maps = await _db.getMixturesByProject(projectId);
    return maps.map((map) => Mixture.fromMap(map)).toList();
  }

  Future<Mixture?> getMixtureById(int id) async {
    final map = await _db.getMixtureById(id);
    return map != null ? Mixture.fromMap(map) : null;
  }

  Future<Mixture?> getMixtureWithMaterials(int id) async {
    final mixture = await getMixtureById(id);
    if (mixture == null) return null;

    final materialMaps = await _db.getMaterialsInMixture(id);
    final materials = materialMaps.map((map) => MaterialInMixture.fromMap(map)).toList();

    return mixture.copyWith(materials: materials);
  }

  Future<int> createMixture(Mixture mixture) async {
    return await _db.insertMixture(mixture.toMap());
  }

  Future<bool> updateMixture(Mixture mixture) async {
    final result = await _db.updateMixture(mixture.id!, mixture.toMap());
    return result > 0;
  }

  Future<bool> deleteMixture(int id) async {
    final result = await _db.deleteMixture(id);
    return result > 0;
  }

  // === MATERIALES EN MEZCLAS ===
  Future<List<MaterialInMixture>> getMaterialsInMixture(int mixtureId) async {
    final maps = await _db.getMaterialsInMixture(mixtureId);
    return maps.map((map) => MaterialInMixture.fromMap(map)).toList();
  }

  Future<bool> addMaterialToMixture(int mixtureId, int materialId, double quantity) async {
    await _db.addMaterialToMixture(mixtureId, materialId, quantity);
    await _db.calculateAndUpdatePercentages(mixtureId);
    return true;
  }

  Future<bool> updateMaterialInMixture(int mixtureId, int materialId, double quantity) async {
    await _db.updateMaterialInMixture(mixtureId, materialId, quantity);
    await _db.calculateAndUpdatePercentages(mixtureId);
    return true;
  }

  Future<bool> removeMaterialFromMixture(int mixtureId, int materialId) async {
    final result = await _db.removeMaterialFromMixture(mixtureId, materialId);
    if (result > 0) {
      await _db.calculateAndUpdatePercentages(mixtureId);
      return true;
    }
    return false;
  }

  // === MÉTODOS ESPECIALES ===
  Future<int> createExampleMixture(String projectName) async {
    return await _db.createExampleMixture(projectName);
  }

  Future<double> calculateMixtureCost(int mixtureId) async {
    final materials = await getMaterialsInMixture(mixtureId);
    double totalCost = 0.0;
    
    for (var material in materials) {
      totalCost += material.cost;
    }
    
    return totalCost;
  }

  Future<Map<String, double>> getMixtureStatistics(int mixtureId) async {
    final materials = await getMaterialsInMixture(mixtureId);
    
    double totalQuantity = 0.0;
    double totalCost = 0.0;
    int materialCount = materials.length;
    
    for (var material in materials) {
      totalQuantity += material.quantity;
      totalCost += material.cost;
    }
    
    return {
      'totalQuantity': totalQuantity,
      'totalCost': totalCost,
      'materialCount': materialCount.toDouble(),
      'averageCostPerKg': totalQuantity > 0 ? totalCost / totalQuantity : 0.0,
    };
  }
}
