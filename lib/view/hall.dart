// view/hall.dart
import 'dart:io';
import 'package:diapce_aplicationn/main.dart'; // Para el botón Salir del Drawer
import 'package:diapce_aplicationn/core/project_data.dart'; // Asegúrate que la ruta sea correcta
import 'package:diapce_aplicationn/view/create_proyect_screen.dart';

// import 'package:diapce_aplicationn/view/project_details_view.dart'; // Si quieres navegar a detalles
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha en la tarjeta del proyecto

class Hall extends StatefulWidget {
  const Hall({super.key});

  @override
  State<Hall> createState() => _HallState();
}

class _HallState extends State<Hall> {
  final List<ProjectData> _projects = [];

  void _navigateToCreateProject() async {
    final newProject = await Navigator.push<ProjectData>(
      context,
      MaterialPageRoute(builder: (context) => const CreateProjectScreen()),
    );

    if (newProject != null && mounted) {
      setState(() {
        _projects.add(newProject);
      });
    }
  }

  void _viewProjectDetails(ProjectData project) {
    print("Viendo detalles del proyecto: ${project.projectName}");
    // Implementa la navegación a ProjectDetailsView si es necesario
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ProjectDetailsView(
    //       projectName: project.projectName,
    //       selectedDate: project.selectedDate,
    //       selectedImage: project.selectedImage,
    //       creatorName: project.creatorName,
    //       resistanceLevel: project.resistanceLevel,
    //       temperature: project.temperature,
    //       humidity: project.humidity,
    //       workType: project.workType,
    //     ),
    //   ),
    // );
  }

  String _formatDateForCard(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return DateFormat('dd/MM/yy').format(date);
  }

  void _handleLinkAction() {
    // TODO: Implementa aquí la lógica para el botón de "vincular" o la acción deseada
    print("Botón de Vincular/Acción presionado");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Acción de vincular no implementada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF2C3E50),
              ),
              child: Center(
                child: Text(
                  'Menú',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color.fromARGB(255, 247, 1, 1)),
              title: const Text('Salir', style: TextStyle(fontSize: 20)),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainApp()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text('DIAPCE',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Vincular',
            onPressed: _handleLinkAction,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _navigateToCreateProject,
              child: Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueGrey, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: const Icon(Icons.add, size: 36, color: Colors.blueGrey),
              ),
            ),
            const Text(
              "Mis Proyectos",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _projects.isEmpty
                  ? const Center( // ***** MENSAJE RESTAURADO *****
                      child: Text(
                        'No hay proyectos creados.\nToca el botón "+" para añadir uno.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12.0,
                        mainAxisSpacing: 12.0,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _projects.length,
                      itemBuilder: (context, index) {
                        final project = _projects[index];
                        return GestureDetector(
                          onTap: () => _viewProjectDetails(project),
                          child: Container( // ***** CONTENIDO DE LA TARJETA RESTAURADO *****
                            decoration: BoxDecoration(
                              color: Colors.teal[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.teal, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                )
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: project.selectedImage != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12.0),
                                            child: Image.file(
                                              project.selectedImage!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            ),
                                          )
                                        : Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.circular(12.0),
                                            ),
                                            child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                                          ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          project.projectName,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        if (project.selectedDate != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatDateForCard(project.selectedDate),
                                            style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}