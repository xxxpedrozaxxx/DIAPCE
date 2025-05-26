// lib/view/view_existing_project_screen.dart

import 'package:diapce_aplicationn/core/project_data.dart'; // Importa tu modelo
import 'package:diapce_aplicationn/core/database_helper.dart';
import 'package:diapce_aplicationn/services/mixture_service.dart';
import 'package:diapce_aplicationn/models/mixture.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ViewExistingProjectScreen extends StatefulWidget {
  final ProjectData project; // Recibirá el objeto ProjectData completo
  final bool isNewProject;
  const ViewExistingProjectScreen({
    Key? key,
    required this.project,
    required this.isNewProject,
  }) : super(key: key);

  @override
  State<ViewExistingProjectScreen> createState() =>
      _ViewExistingProjectScreenState();
}

class _ViewExistingProjectScreenState extends State<ViewExistingProjectScreen> {
  final MixtureService _mixtureService = MixtureService();
  List<MaterialInMixture> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMixtureData();
  }

  Future<void> _loadMixtureData() async {
    if (widget.project.mixtureId != null) {
      try {
        final mixture = await _mixtureService.getMixtureWithMaterials(
          widget.project.mixtureId!,
        );
        if (mixture != null && mounted) {
          setState(() {
            _materials = mixture.materials ?? [];
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }    } else {
      // Crear una instancia local de DatabaseHelper
      final dbHelper = DatabaseHelper();
      final mixtureId = await dbHelper.createRandomExampleMixture(
        widget.project.projectName,
      );
      
      // Cargar los materiales de la mezcla recién creada
      try {
        final mixture = await _mixtureService.getMixtureWithMaterials(mixtureId);
        if (mixture != null && mounted) {
          setState(() {
            _materials = mixture.materials ?? [];
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No especificada';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Crear datos para la gráfica de pastel
  List<PieChartSectionData> _createPieChartSections() {
    if (_materials.isEmpty) return [];

    final colors = [
      const Color(0xFF3498DB), // Azul
      const Color(0xFF2ECC71), // Verde
      const Color(0xFFE67E22), // Naranja
      const Color(0xFFE74C3C), // Rojo
      const Color(0xFF9B59B6), // Púrpura
      const Color(0xFFF39C12), // Amarillo
      const Color(0xFF34495E), // Gris oscuro
      const Color(0xFF1ABC9C), // Turquesa
    ];

    return _materials.asMap().entries.map((entry) {
      final index = entry.key;
      final material = entry.value;
      final percentage = material.percentage ?? 0.0;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // Crear datos para la gráfica de resistencia vs tiempo (28 días)
  List<FlSpot> _createResistanceData() {
    // Obtener el valor de resistencia del proyecto o usar un valor por defecto
    final targetResistance =
        double.tryParse(widget.project.resistanceLevel ?? '25') ?? 25.0;

    // Datos típicos de desarrollo de resistencia del concreto
    // Porcentajes aproximados de la resistencia final a diferentes días
    final resistancePercentages = {
      1: 0.15, // 15% al día 1
      3: 0.35, // 35% al día 3
      7: 0.65, // 65% a los 7 días
      14: 0.85, // 85% a los 14 días
      21: 0.92, // 92% a los 21 días
      28: 1.0, // 100% a los 28 días (resistencia de diseño)
    };

    List<FlSpot> spots = [];

    // Crear puntos para cada día del 1 al 28
    for (int day = 1; day <= 28; day++) {
      double resistanceRatio;

      if (resistancePercentages.containsKey(day)) {
        resistanceRatio = resistancePercentages[day]!;
      } else {
        // Interpolación para días intermedios
        if (day < 3) {
          resistanceRatio = 0.15 + (0.35 - 0.15) * (day - 1) / (3 - 1);
        } else if (day < 7) {
          resistanceRatio = 0.35 + (0.65 - 0.35) * (day - 3) / (7 - 3);
        } else if (day < 14) {
          resistanceRatio = 0.65 + (0.85 - 0.65) * (day - 7) / (14 - 7);
        } else if (day < 21) {
          resistanceRatio = 0.85 + (0.92 - 0.85) * (day - 14) / (21 - 14);
        } else {
          resistanceRatio = 0.92 + (1.0 - 0.92) * (day - 21) / (28 - 21);
        }
      }

      final resistance = targetResistance * resistanceRatio;
      spots.add(FlSpot(day.toDouble(), resistance));
    }

    return spots;
  }

  // Widget para mostrar la leyenda de la gráfica
  Widget _buildPieChartLegend() {
    if (_materials.isEmpty) return const SizedBox.shrink();

    final colors = [
      const Color(0xFF3498DB), // Azul
      const Color(0xFF2ECC71), // Verde
      const Color(0xFFE67E22), // Naranja
      const Color(0xFFE74C3C), // Rojo
      const Color(0xFF9B59B6), // Púrpura
      const Color(0xFFF39C12), // Amarillo
      const Color(0xFF34495E), // Gris oscuro
      const Color(0xFF1ABC9C), // Turquesa
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          _materials.asMap().entries.map((entry) {
            final index = entry.key;
            final material = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${material.materialName}: ${material.quantity.toStringAsFixed(1)} ${material.unit}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        title: Text(
          widget.project.projectName,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Detalles del Proyecto",
                  style: const TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              if (widget.project.selectedImage != null) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(
                      widget.project.selectedImage!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
              _buildDetailRow(
                'Fecha:',
                _formatDate(widget.project.selectedDate),
              ),
              _buildDetailRow(
                'Creador:',
                widget.project.creatorName ?? 'No especificado',
              ),
              _buildDetailRow(
                'Resistencia (MPa):',
                widget.project.resistanceLevel ?? 'No especificado',
              ),
              _buildDetailRow(
                'Temperatura (°C):',
                widget.project.temperature ?? 'No especificado',
              ),
              _buildDetailRow(
                'Humedad (%):',
                widget.project.humidity ?? 'No especificado',
              ),
              _buildDetailRow(
                'Tipo de Obra:',
                widget.project.workType ?? 'No especificado',
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),

              // Sección de Composición de Materiales
              const Text(
                'Composición de Materiales',
                style: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_materials.isEmpty)
                const Center(
                  child: Text(
                    'No hay datos de mezcla disponibles',
                    style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
                  ),
                )
              else ...[
                // Gráfica de pastel
                Container(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: PieChart(
                          PieChartData(
                            sections: _createPieChartSections(),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(flex: 3, child: _buildPieChartLegend()),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Lista detallada de materiales
                const Text(
                  'Detalles de Materiales:',
                  style: TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                for (var material in _materials)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0E6ED)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.materialName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cantidad: ${material.quantity.toStringAsFixed(1)} ${material.unit}',
                              style: const TextStyle(color: Color(0xFF34495E)),
                            ),
                            Text(
                              'Porcentaje: ${(material.percentage ?? 0).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Color(0xFF27AE60),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 15),
              const Center(
                child: Text(
                  'Gráfica de Resistencia',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Resistencia (MPa) vs. Tiempo (28 días)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF34495E),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Gráfica de línea para resistencia vs tiempo
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E6ED)),
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 5,
                      verticalInterval: 7,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: const Color(0xFFE0E6ED),
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: const Color(0xFFE0E6ED),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 7,
                          getTitlesWidget: (value, meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                '${value.toInt()}',
                                style: const TextStyle(
                                  color: Color(0xFF7F8C8D),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(
                                color: Color(0xFF7F8C8D),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                          reservedSize: 42,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: const Color(0xFFE0E6ED)),
                    ),
                    minX: 0,
                    maxX: 28,
                    minY: 0,
                    maxY:
                        (double.tryParse(
                              widget.project.resistanceLevel ?? '25',
                            ) ??
                            25.0) *
                        1.1,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _createResistanceData(),
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3498DB), Color(0xFF2ECC71)],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF2C3E50),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF3498DB).withOpacity(0.3),
                              const Color(0xFF2ECC71).withOpacity(0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Información adicional sobre la gráfica
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E6ED)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de la gráfica:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Eje X: Tiempo en días (0-28)',
                      style: TextStyle(fontSize: 12, color: Color(0xFF34495E)),
                    ),
                    const Text(
                      '• Eje Y: Resistencia en MPa',
                      style: TextStyle(fontSize: 12, color: Color(0xFF34495E)),
                    ),
                    Text(
                      '• Resistencia objetivo: ${widget.project.resistanceLevel ?? '25'} MPa a los 28 días',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF34495E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

                Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  _buildButton('Descargar', Colors.blue, () {
                    // Acción de descarga aquí
                  }),
                  const SizedBox(width: 16),
                  if (widget.isNewProject == true)
                    _buildButton('Guardar', Colors.green, () {
                      // Acción de guardar aquí
                      // Por ejemplo, guardar el proyecto en la base de datos
                      //DatabaseHelper().insertMaterial(mate);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Proyecto guardado')),
                      );
                    }),
                  
                  ],
                ),
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
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF34495E), fontSize: 16),
            ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }
}
