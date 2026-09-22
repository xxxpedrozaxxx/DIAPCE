import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Dato numérico protagonista (equivalente al "precio" en e-commerce):
/// etiqueta pequeña, valor grande y unidad. `highlight` lo pinta en primario.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final bool highlight;
  final IconData? icon;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.highlight = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    final bg = highlight ? scheme.primary : scheme.surface;
    final fg = highlight ? scheme.onPrimary : scheme.onSurface;
    final muted = highlight
        ? scheme.onPrimary.withValues(alpha: 0.75)
        : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.cardAll,
        boxShadow: AppShadows.soft(theme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: muted),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: text.labelSmall?.copyWith(color: muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: text.headlineMedium?.copyWith(color: fg),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(unit!, style: text.labelMedium?.copyWith(color: muted)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
