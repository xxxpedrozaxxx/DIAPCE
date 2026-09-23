import 'package:diapce_aplicationn/components/app_button.dart';
import 'package:diapce_aplicationn/components/app_card.dart';
import 'package:diapce_aplicationn/components/empty_state.dart';
import 'package:diapce_aplicationn/components/fade_slide_in.dart';
import 'package:diapce_aplicationn/core/theme/app_spacing.dart';
import 'package:diapce_aplicationn/services/auth_service.dart';
import 'package:diapce_aplicationn/models/project_data.dart';
import 'package:diapce_aplicationn/services/project_service.dart';
import 'package:diapce_aplicationn/view/ViewExistingProjectScreen.dart';
import 'package:diapce_aplicationn/view/analysis_screen.dart';
import 'package:diapce_aplicationn/view/create_proyect_screen.dart';
import 'package:diapce_aplicationn/view/main_login.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tag de Hero compartido entre la tarjeta del proyecto y su pantalla de detalle.
String projectHeroTag(ProjectData project) =>
    'project-image-${project.id ?? project.projectName}';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando proyectos: $e')));
      }
    }
  }

  void _navigateToCreateProject() async {
    final newProject = await Navigator.push<ProjectData>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateProjectScreen(),
      ),
    );

    if (newProject != null && mounted) {
      setState(() {
        _projects.add(newProject);
      });
    }
  }

  void _viewProjectDetails(ProjectData project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ViewExistingProjectScreen(
              project: project,
              isNewProject: false,
            ),
      ),
    );
  }

  String _formatDateForCard(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _openAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalysisScreen()),
    );
  }

  void _handleLinkAction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Acción de vincular no implementada')),
    );
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainLogin()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _deleteProject(ProjectData project) async {
    final scheme = Theme.of(context).colorScheme;
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar proyecto'),
          content: Text(
            '¿Seguro que quieres eliminar "${project.projectName}"?\n\nEsta acción no se puede deshacer.',
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          actions: [
            AppButton.text(
              label: 'Cancelar',
              onPressed: () => Navigator.of(context).pop(false),
            ),
            AppButton(
              label: 'Eliminar',
              expand: false,
              color: scheme.error,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && project.id != null) {
      try {
        final success = await _projectService.deleteProject(project.id!);

        if (success && mounted) {
          setState(() {
            _projects.removeWhere((p) => p.id == project.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Proyecto "${project.projectName}" eliminado'),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error al eliminar el proyecto'),
              backgroundColor: scheme.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: scheme.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final email = (widget.user['email'] ?? '') as String;

    return Scaffold(
      drawer: _AppDrawer(
        email: email,
        onLogout: _logout,
        onAnalysis: () {
          Navigator.pop(context);
          _openAnalysis();
        },
      ),
      appBar: AppBar(
        title: Text(
          'DIAPCE',
          style: text.titleMedium?.copyWith(letterSpacing: 3),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded),
            tooltip: 'Análisis de laboratorio',
            onPressed: _openAnalysis,
          ),
          IconButton(
            icon: const Icon(Icons.link_rounded),
            tooltip: 'Vincular',
            onPressed: _handleLinkAction,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: FadeSlideIn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mis proyectos', style: text.displayMedium),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _projects.isEmpty
                                  ? 'Aún no tienes proyectos'
                                  : '${_projects.length} ${_projects.length == 1 ? 'proyecto' : 'proyectos'} · mantén presionado para eliminar',
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_projects.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.foundation_rounded,
                        title: 'Empieza tu primer proyecto',
                        message:
                            'Define las condiciones de obra y obtén la predicción de resistencia a 7, 14 y 28 días.',
                        action: AppButton(
                          label: 'Crear proyecto',
                          icon: Icons.add_rounded,
                          expand: false,
                          onPressed: _navigateToCreateProject,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                              childAspectRatio: 0.74,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (index == 0) {
                            return FadeSlideIn(
                              index: index,
                              child: _NewProjectCard(
                                onTap: _navigateToCreateProject,
                              ),
                            );
                          }
                          final project = _projects[index - 1];
                          return FadeSlideIn(
                            index: index,
                            child: _ProjectCard(
                              project: project,
                              number: index,
                              dateLabel: _formatDateForCard(
                                project.selectedDate,
                              ),
                              onTap: () => _viewProjectDetails(project),
                              onLongPress: () => _deleteProject(project),
                            ),
                          );
                        }, childCount: _projects.length + 1),
                      ),
                    ),
                ],
              ),
    );
  }
}

// ── Widgets privados ──────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final ProjectData project;
  final int number;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ProjectCard({
    required this.project,
    required this.number,
    required this.dateLabel,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: projectHeroTag(project),
                  child:
                      project.selectedImage != null
                          ? Image.file(
                            project.selectedImage!,
                            fit: BoxFit.cover,
                          )
                          : Container(
                            color: scheme.primaryContainer,
                            child: Icon(
                              Icons.apartment_rounded,
                              size: 44,
                              color: scheme.primary.withValues(alpha: 0.6),
                            ),
                          ),
                ),
                Positioned(
                  top: AppSpacing.sm + 2,
                  left: AppSpacing.sm + 2,
                  child: _Badge(
                    label: number.toString().padLeft(2, '0'),
                    background: scheme.surface.withValues(alpha: 0.92),
                    foreground: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm + 4,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.projectName,
                  style: text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  project.workType == null
                      ? dateLabel
                      : '${project.workType} · $dateLabel',
                  style: text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      project.resistanceTarget.toStringAsFixed(
                        project.resistanceTarget % 1 == 0 ? 0 : 1,
                      ),
                      style: text.titleLarge?.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text('MPa objetivo', style: text.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewProjectCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NewProjectCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return AppCard(
      onTap: onTap,
      color: scheme.primaryContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary,
            ),
            child: Icon(Icons.add_rounded, color: scheme.onPrimary, size: 30),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Crear nuevo',
            style: text.titleMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Nueva mezcla',
            style: text.bodySmall?.copyWith(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: foreground),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final String email;
  final VoidCallback onLogout;
  final VoidCallback onAnalysis;

  const _AppDrawer({
    required this.email,
    required this.onLogout,
    required this.onAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.base),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: scheme.onPrimary,
                  size: 30,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Tu cuenta', style: text.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                email.isEmpty ? 'Usuario' : email,
                style: text.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                leading: Icon(Icons.insights_rounded, color: scheme.primary),
                title: Text('Análisis de laboratorio', style: text.titleMedium),
                onTap: onAnalysis,
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                leading: Icon(Icons.logout_rounded, color: scheme.error),
                title: Text(
                  'Cerrar sesión',
                  style: text.titleMedium?.copyWith(color: scheme.error),
                ),
                onTap: onLogout,
              ),
              const Spacer(),
              Text('DIAPCE · Diseño de mezclas', style: text.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
