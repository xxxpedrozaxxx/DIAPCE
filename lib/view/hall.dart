import 'package:diapce_aplicationn/main.dart';
import 'package:diapce_aplicationn/view/ViewExistingProjectScreen.dart';
import 'package:diapce_aplicationn/models/project_data.dart';
import 'package:diapce_aplicationn/view/create_proyect_screen.dart';
import 'package:diapce_aplicationn/services/project_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class Hall extends StatefulWidget {
  final Map<String, dynamic> user;
  const Hall({super.key, required this.user});

  @override
  State<Hall> createState() => _HallState();
}

class _HallState extends State<Hall> {
  final ProjectService _projectService = ProjectService();
  final List<ProjectData> _projects = [];
  bool _isLoading = true;


  late int _userId;

  @override
  void initState() {
    super.initState();
    _userId = widget.user['id'];
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await _projectService.getAllProjects(userId: _userId);
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
      MaterialPageRoute(builder: (context) => CreateProjectScreen(userId: _userId)),
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
    // Mostrar diálogo de confirmaciónha
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
            const Text(
              "Mis Proyectos",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _projects.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Tarjeta especial para crear nueva (borde hundido)
                          return GestureDetector(
                            onTap: _navigateToCreateProject,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.blueGrey.shade200, width: 2),
                                boxShadow: [
                                  // Borde hundido
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.8),
                                    offset: const Offset(-2, -2),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                  BoxShadow(
                                    color: Colors.blueGrey.shade100,
                                    offset: const Offset(2, 2),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add, size: 48, color: Colors.blueGrey),
                                  SizedBox(height: 12),
                                  Text('Crear nueva', style: TextStyle(fontSize: 18, color: Colors.blueGrey)),
                                ],
                              ),
                            ),
                          );
                        }
                        final project = _projects[index - 1];
                        // Color azul claro igual a la primera tarjeta
                        return GestureDetector(
                          onTap: () => _viewProjectDetails(project),
                          onLongPress: () => _deleteProject(project),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.blueGrey.shade200, width: 2),
                              boxShadow: [
                                // Borde elevado
                                BoxShadow(
                                  color: Colors.blueGrey.shade100,
                                  offset: const Offset(-2, -2),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.8),
                                  offset: const Offset(2, 2),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Número grande en la esquina superior izquierda
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Text(
                                    (index).toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ),
                                // Imagen principal (más abajo y más grande)
                                Positioned(
                                  top: 60,
                                  left: 24,
                                  right: 24,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: project.selectedImage != null
                                        ? Image.file(
                                            project.selectedImage!,
                                            height: 110,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            height: 110,
                                            color: Colors.white,
                                            child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                          ),
                                  ),
                                ),
                                // Nombre del proyecto
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
                                    child: Text(
                                      project.projectName,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.blueGrey,
                                      ),
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