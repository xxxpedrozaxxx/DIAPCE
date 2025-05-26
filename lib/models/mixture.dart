// lib/models/mixture.dart

import 'material.dart';

class Mixture {
  final int? id;
  final String name;
  final String? description;
  final double? totalVolume;
  final int? projectId;
  final String? createdAt;
  final List<MaterialInMixture>? materials;

  Mixture({
    this.id,
    required this.name,
    this.description,
    this.totalVolume,
    this.projectId,
    this.createdAt,
    this.materials,
  });

  factory Mixture.fromMap(Map<String, dynamic> map) {
    return Mixture(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      totalVolume: map['total_volume']?.toDouble(),
      projectId: map['project_id'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'total_volume': totalVolume,
      'project_id': projectId,
      'created_at': createdAt,
    };
  }

  Mixture copyWith({
    int? id,
    String? name,
    String? description,
    double? totalVolume,
    int? projectId,
    String? createdAt,
    List<MaterialInMixture>? materials,
  }) {
    return Mixture(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalVolume: totalVolume ?? this.totalVolume,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      materials: materials ?? this.materials,
    );
  }
}

class MaterialInMixture {
  final int materialId;
  final String materialName;
  final String unit;
  final double quantity;
  final double? percentage;
  final double? density;
  final double? costPerUnit;
  final String? description;

  MaterialInMixture({
    required this.materialId,
    required this.materialName,
    required this.unit,
    required this.quantity,
    this.percentage,
    this.density,
    this.costPerUnit,
    this.description,
  });

  factory MaterialInMixture.fromMap(Map<String, dynamic> map) {
    return MaterialInMixture(
      materialId: map['id'],
      materialName: map['name'],
      unit: map['unit'],
      quantity: map['quantity']?.toDouble() ?? 0.0,
      percentage: map['percentage']?.toDouble(),
      density: map['density']?.toDouble(),
      costPerUnit: map['cost_per_unit']?.toDouble(),
      description: map['description'],
    );
  }

  double get cost => (costPerUnit ?? 0.0) * quantity;
}
