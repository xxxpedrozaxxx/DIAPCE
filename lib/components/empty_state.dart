import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Pantalla de estado (vacío / sin datos): ícono grande sobre disco tonal,
/// título, mensaje y acción opcional.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: AppMotion.slow,
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primaryContainer,
                ),
                child: Icon(icon, size: 52, color: scheme.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
