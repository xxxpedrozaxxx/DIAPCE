import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Barra inferior fija con acciones; fondo surface y sombra hacia arriba.
/// Úsala en `Scaffold.bottomNavigationBar`.
class BottomActionBar extends StatelessWidget {
  final List<Widget> children;
  const BottomActionBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.4 : 0.06,
            ),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md,
          ),
          child: Row(children: children),
        ),
      ),
    );
  }
}
