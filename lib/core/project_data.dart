// models/project_data.dart o core/project_data.dart (dependiendo de dónde la tengas)
import 'dart:io'; // Necesario para 'File'

class ProjectData {
  final String projectName;
  final DateTime? selectedDate;
  final File? selectedImage; // Para la imagen seleccionada
  final String? creatorName;
  final String? resistanceLevel; // De Properties
  final String? temperature;     // De Properties
  final String? humidity;        // De Properties
  final String? workType;        // De Properties

  ProjectData({
    required this.projectName,
    this.selectedDate,
    this.selectedImage,
    this.creatorName,
    this.resistanceLevel,
    this.temperature,
    this.humidity,
    this.workType,
  });

  // Opcional: Un método 'copyWith' puede ser útil si necesitas modificar instancias
  // ProjectData copyWith({
  //   String? projectName,
  //   DateTime? selectedDate,
  //   ValueGetter<File?>? selectedImage, // Usar ValueGetter para manejar null de forma explícita
  //   String? creatorName,
  //   String? resistanceLevel,
  //   String? temperature,
  //   String? humidity,
  //   String? workType,
  // }) {
  //   return ProjectData(
  //     projectName: projectName ?? this.projectName,
  //     selectedDate: selectedDate ?? this.selectedDate,
  //     selectedImage: selectedImage != null ? selectedImage() : this.selectedImage,
  //     creatorName: creatorName ?? this.creatorName,
  //     resistanceLevel: resistanceLevel ?? this.resistanceLevel,
  //     temperature: temperature ?? this.temperature,
  //     humidity: humidity ?? this.humidity,
  //     workType: workType ?? this.workType,
  //   );
  // }

  // Opcional: Un método 'toString' para facilitar la depuración
  @override
  String toString() {
    return 'ProjectData(projectName: $projectName, selectedDate: $selectedDate, creatorName: $creatorName, resistanceLevel: $resistanceLevel, temperature: $temperature, humidity: $humidity, workType: $workType, selectedImage: ${selectedImage?.path})';
  }
}