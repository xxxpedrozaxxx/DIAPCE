import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Encabezado de sección: sobretítulo pequeño en mayúsculas opcional,
/// título y subtítulo en gris. Acción opcional a la derecha.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;
  final TextStyle? titleStyle;

  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: text.labelSmall?.copyWith(color: scheme.primary),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(title, style: titleStyle ?? text.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle!, style: text.bodySmall),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
