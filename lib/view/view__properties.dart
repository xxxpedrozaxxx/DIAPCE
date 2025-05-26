// lib/view/project_details_view.dart

import 'dart:io'; // Para File si se usa
import 'package:diapce_aplicationn/core/project_data.dart'; // Importa tu modelo
// import 'package:diapce_aplicationn/view/graph_view.dart'; // Ya no se necesita
import 'package:diapce_aplicationn/view/hall.dart'; // Para el botón Cerrar
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha

// Volvemos a StatelessWidget ya que no hay estado interno complejo
class ProjectDetailsView extends StatelessWidget {
  final String projectName;
  final DateTime? selectedDate;
  final File? selectedImage;
  final String? creatorName;
  final String? resistanceLevel;
  final String? temperature;
  final String? humidity;
  final String? workType;

  const ProjectDetailsView({
    Key? key,
    required this.projectName,
    this.selectedDate,
    this.selectedImage,
    this.creatorName,
    this.resistanceLevel,
    this.temperature,
    this.humidity,
    this.workType,
  }) : super(key: key);

  String _formatDate(DateTime? date) {
    if (date == null) return 'No especificada';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Función para manejar la acción de descarga (placeholder)
  void _handleDownload(BuildContext context) {
    // TODO: Implementar la lógica de descarga aquí.
    // Esto podría involucrar:
    // 1. Decidir qué descargar (datos del proyecto, imágenes, un PDF combinado).
    // 2. Usar paquetes como 'path_provider', 'dio' (para descargar de URLs),
    //    'image_downloader' (móvil), 'universal_html' (web), 'pdf' (para generar PDFs).
    // 3. Solicitar permisos si es necesario (para almacenamiento).
    print("Botón Descargar presionado");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de descarga no implementada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        title: const Text('Detalles del Proyecto'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { /* Lógica de refresco */ },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  projectName,
                  style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 22,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 15),
              if (selectedImage != null) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(selectedImage!,
                        height: 180, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 15),
              ],
              _buildDetailRow('Fecha:', _formatDate(selectedDate)),
              _buildDetailRow('Creador:', creatorName ?? 'No especificado'),
              _buildDetailRow('Resistencia (MPa):', resistanceLevel ?? 'No especificado'),
              _buildDetailRow('Temperatura (°C):', temperature ?? 'No especificado'),
              _buildDetailRow('Humedad (%):', humidity ?? 'No especificado'),
              _buildDetailRow('Tipo de Obra:', workType ?? 'No especificado'),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text('Dosificación (Ejemplo)',
                  style: TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _buildDetailRow('Cantidad de cemento (kg.):', '350'),
              _buildDetailRow('Cantidad de agua (L.):', '180'),
              _buildDetailRow('Agregado Fino (kg.):', '700'),
              _buildDetailRow('Agregado Grueso (kg.):', '1100'),
              _buildDetailRow('Aditivo Súper (L.):', '1.5'),
              
              const SizedBox(height: 20),
              // Las gráficas ahora se muestran siempre
              const Divider(),
              const SizedBox(height: 15),
              const Center(
                child: Text(
                  'Gráficas de Referencia',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50)),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Resistencia (MPa) vs. Tiempo/Curado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF34495E),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildGraphImage('https://portal.amelica.org/ameli/journal/595/5952727005/5952727005_gf3.png'),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Esfuerzo (MPa) vs. Deformación Unitaria',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF34495E)),
                ),
              ),
              const SizedBox(height: 8),
              _buildGraphImage('https://www.researchgate.net/publication/335582614/figure/fig2/AS:11431281114971958@1674734691367/Figura-9-Curvas-representativas-de-esfuerzo-MPa-versus-deformacion-unitaria-mm-mm.png'),
              const SizedBox(height: 30), // Más espacio antes de los botones
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildButton('Cerrar', Colors.orange, () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }),
                  _buildButton( // Nuevo botón de Descargar
                    'Descargar',
                    const Color(0xFF3498DB), // Mismo color que tenía "Graficar"
                    () => _handleDownload(context), // Llama a la nueva función
                  ),
                  _buildButton('Guardar', const Color(0xFF27AE60), () {
                    final project = ProjectData(
                      projectName: projectName,
                      selectedDate: selectedDate,
                      selectedImage: selectedImage,
                      creatorName: creatorName,
                      resistanceLevel: resistanceLevel,
                      temperature: temperature,
                      humidity: humidity,
                      workType: workType,
                    );
                    Navigator.pop(context, project);
                  }),
                ],
              ),
              const SizedBox(height: 20), // Espacio al final del scroll
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: Color(0xFF34495E), fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontSize: 15)),
    );
  }

  Widget _buildGraphImage(String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          imageUrl,
          height: 230,
          width: double.infinity,
          fit: BoxFit.contain,
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
            return Container(
              height: 230,
              color: Colors.grey[300],
              child: const Center(child: Text('Error al cargar imagen', style: TextStyle(color: Colors.redAccent))),
            );
          },
        ),
      ),
    );
  }
}