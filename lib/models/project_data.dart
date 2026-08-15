// models/project_data.dart o core/project_data.dart (dependiendo de dónde la tengas)
import 'dart:io'; // Necesario para 'File'

class ProjectData {
  final int? id; // ID de la base de datos
  final int? userId; // ID del usuario dueño del proyecto
  final String projectName;
  final DateTime? selectedDate;
  final File? selectedImage; // Para la imagen seleccionada
  final String? creatorName;
  final String? workType;        // De Properties
  final double resistanceTarget; // Resistencia objetivo en MPa (24-57 con hasta 2 decimales)
  final int temperature;     // Temperatura en grados Celsius
  final int humidity;        // Humedad relativa en porcentaje
  final double relacionAc;   // Relación agua/cemento
  final int? aditivoId;      // ID del aditivo seleccionado
  final double? resistenciaPredicha7d;  // Predicción a 7 días
  final double? resistenciaPredicha14d; // Predicción a 14 días
  final double? resistenciaPredicha28d; // Predicción a 28 días
  final int? mixtureId;      // ID de la mezcla asociada

  ProjectData({
    this.id,
    this.userId,
    required this.projectName,
    this.selectedDate,
    this.selectedImage,
    this.creatorName,
    this.workType,
    required this.resistanceTarget,
    required this.temperature,
    required this.humidity,
    required this.relacionAc,
    this.aditivoId,
    this.resistenciaPredicha7d,
    this.resistenciaPredicha14d,
    this.resistenciaPredicha28d,
    this.mixtureId,
  });

  // Método para convertir desde Map (desde la base de datos)
  factory ProjectData.fromMap(Map<String, dynamic> map) {
    return ProjectData(
      id: map['id'],
      userId: map['user_id'],
      projectName: map['project_name'],
      selectedDate: map['selected_date'] != null 
          ? DateTime.parse(map['selected_date']) 
          : null,
      selectedImage: map['selected_image_path'] != null 
          ? File(map['selected_image_path']) 
          : null,
      creatorName: map['creator_name'],
      workType: map['work_type'],
      resistanceTarget: (map['resistance_target'] as num?)?.toDouble() ?? 28.0,
      temperature: map['temperature'] ?? 25,
      humidity: map['humidity'] ?? 50,
      relacionAc: map['relacion_ac']?.toDouble() ?? 0.5,
      aditivoId: map['aditivo_id'],
      resistenciaPredicha7d: map['resistencia_predicha_7d']?.toDouble(),
      resistenciaPredicha14d: map['resistencia_predicha_14d']?.toDouble(),
      resistenciaPredicha28d: map['resistencia_predicha_28d']?.toDouble(),
      mixtureId: map['mixture_id'],
    );
  }

  // Método para convertir a Map (para guardar en la base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'project_name': projectName,
      'selected_date': selectedDate?.toIso8601String(),
      'selected_image_path': selectedImage?.path,
      'creator_name': creatorName,
      'work_type': workType,
      'resistance_target': resistanceTarget,
      'temperature': temperature,
      'humidity': humidity,
      'relacion_ac': relacionAc,
      'aditivo_id': aditivoId,
      'resistencia_predicha_7d': resistenciaPredicha7d,
      'resistencia_predicha_14d': resistenciaPredicha14d,
      'resistencia_predicha_28d': resistenciaPredicha28d,
      'mixture_id': mixtureId,
    };
  }

  // Método copyWith para crear copias con campos modificados
  ProjectData copyWith({
    int? id,
    int? userId,
    String? projectName,
    DateTime? selectedDate,
    File? selectedImage,
    String? creatorName,
    String? workType,
    double? resistanceTarget,
    int? temperature,
    int? humidity,
    double? relacionAc,
    int? aditivoId,
    double? resistenciaPredicha7d,
    double? resistenciaPredicha14d,
    double? resistenciaPredicha28d,
    int? mixtureId,
  }) {
    return ProjectData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectName: projectName ?? this.projectName,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedImage: selectedImage ?? this.selectedImage,
      creatorName: creatorName ?? this.creatorName,
      workType: workType ?? this.workType,
      resistanceTarget: resistanceTarget ?? this.resistanceTarget,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      relacionAc: relacionAc ?? this.relacionAc,
      aditivoId: aditivoId ?? this.aditivoId,
      resistenciaPredicha7d: resistenciaPredicha7d ?? this.resistenciaPredicha7d,
      resistenciaPredicha14d: resistenciaPredicha14d ?? this.resistenciaPredicha14d,
      resistenciaPredicha28d: resistenciaPredicha28d ?? this.resistenciaPredicha28d,
      mixtureId: mixtureId ?? this.mixtureId,
    );
  }

  // Opcional: Un método 'toString' para facilitar la depuración
  @override
  String toString() {
    return 'ProjectData(id: $id, userId: $userId, projectName: $projectName, temperature: $temperature, humidity: $humidity, relacionAc: $relacionAc)';
  }
}