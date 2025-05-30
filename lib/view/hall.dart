import 'package:diapce_aplicationn/main.dart'; 
import 'package:diapce_aplicationn/view/ViewExistingProjectScreen.dart';
import 'package:diapce_aplicationn/models/project_data.dart';
import 'package:diapce_aplicationn/view/create_proyect_screen.dart';
import 'package:diapce_aplicationn/services/project_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Hall extends StatefulWidget {
  const Hall({super.key});

  @override
  State<Hall> createState() => _HallState();
}

class _HallState extends State<Hall> {
  final ProjectService _projectService = ProjectService();
  final List<ProjectData> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await _projectService.getAllProjects();
      if (mounted) {
        setState(() {
          _projects.clear();
          _projects.addAll(projects);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando proyectos: $e')),
        );
      }
    }
  }
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

  // MODIFICADO: Ahora navega a ViewExistingProjectScreen
  void _viewProjectDetails(ProjectData project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewExistingProjectScreen(project: project, isNewProject: false,), // Pasa el objeto project completo
      ),
    );
  }

  String _formatDateForCard(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return DateFormat('dd/MM/yy').format(date);
  }
  void _handleLinkAction() {
    print("Botón de Vincular/Acción presionado");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Acción de vincular no implementada')),
    );
  }

  Future<void> _deleteProject(ProjectData project) async {
    // Mostrar diálogo de confirmación
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Proyecto'),
          content: Text(
            '¿Estás seguro de que quieres eliminar el proyecto "${project.projectName}"?\n\nEsta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    // Si el usuario confirmó la eliminación
    if (shouldDelete == true && project.id != null) {
      try {
        final success = await _projectService.deleteProject(project.id!);
        
        if (success && mounted) {
          setState(() {
            _projects.removeWhere((p) => p.id == project.id);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Proyecto "${project.projectName}" eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar el proyecto'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
            const SizedBox(height: 10),            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _projects.isEmpty
                      ? const Center(
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
                        final project = _projects[index];                        return GestureDetector(
                          onTap: () => _viewProjectDetails(project),
                          onLongPress: () => _deleteProject(project), // Añadir long press para eliminar
                          child: Container(
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