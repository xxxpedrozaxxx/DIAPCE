// models/project_data.dart o core/project_data.dart (dependiendo de dónde la tengas)
import 'dart:io'; // Necesario para 'File'

class ProjectData {
  final int? id; // ID de la base de datos
  final String projectName;
  final DateTime? selectedDate;
  final File? selectedImage; // Para la imagen seleccionada
  final String? creatorName;
  final String? resistanceLevel; // De Properties
  final String? temperature;     // De Properties
  final String? humidity;        // De Properties
  final String? workType;        // De Properties
  final int? mixtureId;// ID de la mezcla asociada

  ProjectData({
    this.id,
    required this.projectName,
    this.selectedDate,
    this.selectedImage,
    this.creatorName,
    this.resistanceLevel,
    this.temperature,
    this.humidity,
    this.workType,
    this.mixtureId,
  });

  // Método para convertir desde Map (desde la base de datos)
  factory ProjectData.fromMap(Map<String, dynamic> map) {
    return ProjectData(
      id: map['id'],
      projectName: map['project_name'],
      selectedDate: map['selected_date'] != null 
          ? DateTime.parse(map['selected_date']) 
          : null,
      selectedImage: map['selected_image_path'] != null 
          ? File(map['selected_image_path']) 
          : null,
      creatorName: map['creator_name'],
      resistanceLevel: map['resistance_level'],
      temperature: map['temperature'],
      humidity: map['humidity'],
      workType: map['work_type'],
      mixtureId: map['mixture_id'],
    );
  }

  // Método para convertir a Map (para guardar en la base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_name': projectName,
      'selected_date': selectedDate?.toIso8601String(),
      'selected_image_path': selectedImage?.path,
      'creator_name': creatorName,
      'resistance_level': resistanceLevel,
      'temperature': temperature,
      'humidity': humidity,
      'work_type': workType,
      'mixture_id': mixtureId,
    };
  }

  // Método copyWith para crear copias con campos modificados
  ProjectData copyWith({
    int? id,
    String? projectName,
    DateTime? selectedDate,
    File? selectedImage,
    String? creatorName,
    String? resistanceLevel,
    String? temperature,
    String? humidity,
    String? workType,
    int? mixtureId,
  }) {
    return ProjectData(
      id: id ?? this.id,
      projectName: projectName ?? this.projectName,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedImage: selectedImage ?? this.selectedImage,
      creatorName: creatorName ?? this.creatorName,
      resistanceLevel: resistanceLevel ?? this.resistanceLevel,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      workType: workType ?? this.workType,
      mixtureId: mixtureId ?? this.mixtureId,
    );
  }

  // Opcional: Un método 'toString' para facilitar la depuración
  @override
  String toString() {
    return 'ProjectData(id: $id, projectName: $projectName, selectedDate: $selectedDate, creatorName: $creatorName, resistanceLevel: $resistanceLevel, temperature: $temperature, humidity: $humidity, workType: $workType, selectedImage: ${selectedImage?.path}, mixtureId: $mixtureId)';
  }
}