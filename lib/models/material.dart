// lib/models/material.dart

class Material {
  final int? id;
  final String name;
  final String unit;
  final double? density;
  final double? costPerUnit;
  final String? description;
  final String? createdAt;

  Material({
    this.id,
    required this.name,
    required this.unit,
    this.density,
    this.costPerUnit,
    this.description,
    this.createdAt,
  });

  factory Material.fromMap(Map<String, dynamic> map) {
    return Material(
      id: map['id'],
      name: map['name'],
      unit: map['unit'],
      density: map['density']?.toDouble(),
      costPerUnit: map['cost_per_unit']?.toDouble(),
      description: map['description'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'density': density,
      'cost_per_unit': costPerUnit,
      'description': description,
      'created_at': createdAt,
    };
  }

  Material copyWith({
    int? id,
    String? name,
    String? unit,
    double? density,
    double? costPerUnit,
    String? description,
    String? createdAt,
  }) {
    return Material(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      density: density ?? this.density,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
