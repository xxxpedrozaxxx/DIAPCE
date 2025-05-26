// lib/view/view_existing_project_screen.dart

import 'dart:io';
import 'package:diapce_aplicationn/core/project_data.dart'; // Importa tu modelo
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewExistingProjectScreen extends StatelessWidget {
  final ProjectData project; // Recibirá el objeto ProjectData completo

  const ViewExistingProjectScreen({
    Key? key,
    required this.project,
  }) : super(key: key);

  String _formatDate(DateTime? date) {
    if (date == null) return 'No especificada';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // --- INICIO: Sección de Dosificación de Ejemplo (Placeholder) ---
  // Esta sección podría obtenerse de una base de datos o servicio en el futuro
  // Por ahora, es la misma lógica de selección aleatoria o un diseño fijo.
  // Si quieres que sea diferente por proyecto, necesitarás pasar estos datos
  // también o tener una lógica más compleja aquí.
  // Por simplicidad, mantendremos los datos de ejemplo como en ProjectDetailsView
  // pero con los ajustes solicitados.

  Map<String, String> _getExampleDosage() {
    // Aquí podrías tener lógica para seleccionar un diseño aleatorio
    // de una lista o de una base de datos como discutimos.
    // Por ahora, devolvemos un ejemplo fijo con los campos actualizados.
    return {
      'Cantidad de cemento (kg.)': '350',
      'Cantidad de agua (L.)': '180',
      'Agregado Mixto (kg.)': '1800', // Campo combinado
      'Aditivo (L.)': '1.5', // Etiqueta actualizada
      'Tiempo de Fraguado (horas)': '24-48', // Nuevo campo
    };
  }
  // --- FIN: Sección de Dosificación de Ejemplo ---


  @override
  Widget build(BuildContext context) {
    final exampleDosage = _getExampleDosage(); // Obtiene la dosificación de ejemplo

    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        title: Text(project.projectName, overflow: TextOverflow.ellipsis), // Título con nombre del proyecto
        centerTitle: true,
        // No hay acciones como 'refresh' aquí, a menos que lo necesites
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center( // Moví el nombre del proyecto al AppBar, pero puedes mantenerlo aquí si prefieres
                child: Text(
                  "Detalles del Proyecto", // O podrías repetir project.projectName
                  style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 22, // Ajustado ligeramente
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 15),
              if (project.selectedImage != null) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(project.selectedImage!,
                        height: 180, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 15),
              ],
              _buildDetailRow('Fecha:', _formatDate(project.selectedDate)),
              _buildDetailRow('Creador:', project.creatorName ?? 'No especificado'),
              _buildDetailRow('Resistencia (MPa):', project.resistanceLevel ?? 'No especificado'),
              _buildDetailRow('Temperatura (°C):', project.temperature ?? 'No especificado'),
              _buildDetailRow('Humedad (%):', project.humidity ?? 'No especificado'),
              _buildDetailRow('Tipo de Obra:', project.workType ?? 'No especificado'),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text('Dosificación Aplicada (Ejemplo)', // Título ajustado
                  style: TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              // Mostrar los datos de dosificación obtenidos
              for (var entry in exampleDosage.entries)
                _buildDetailRow(entry.key, entry.value),

              const SizedBox(height: 20),
              // Las gráficas de referencia
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
              const SizedBox(height: 30),

              Center( // Centrar el único botón
                child: _buildButton('Salir', Colors.orange, () {
                  Navigator.pop(context); // Simplemente vuelve a la pantalla anterior (Hall)
                }),
              ),
              const SizedBox(height: 20),
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
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14), // Ajusta el padding si es necesario
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontSize: 16)),
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