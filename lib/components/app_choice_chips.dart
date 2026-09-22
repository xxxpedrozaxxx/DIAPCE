import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Selector de variantes tipo chip (estilo "tallas"/"colores").
///
/// Genérico sobre `T`; `labelBuilder` convierte cada opción en texto.
/// Estado seleccionado: fondo primario sólido + texto onPrimary.
/// Deshabilitado (`enabled == false` u opciones vacías): tono apagado.
class AppChoiceChips<T> extends StatelessWidget {
  final List<T> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String Function(T option) labelBuilder;
  final String? Function(T option)? captionBuilder;
  final bool enabled;
  final String? emptyHint;

  const AppChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
    this.captionBuilder,
    this.enabled = true,
    this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (options.isEmpty) {
      return AnimatedOpacity(
        opacity: 0.6,
        duration: AppMotion.normal,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: AppRadius.baseAll,
          ),
          child: Text(
            emptyHint ?? 'Selecciona la opción anterior primero',
            style: theme.textTheme.bodySmall,
          ),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in options)
          _Chip(
            label: labelBuilder(option),
            caption: captionBuilder?.call(option),
            selected: option == selected,
            enabled: enabled,
            onTap: () => onSelected(option),
          ),
      ],
    );
  }
}

class _Chip extends StatefulWidget {
  final String label;
  final String? caption;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    this.caption,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = widget.selected;
    final enabled = widget.enabled;

    final bg = !enabled
        ? scheme.surfaceContainerHighest
        : selected
            ? scheme.primary
            : scheme.surface;
    final fg = !enabled
        ? scheme.onSurfaceVariant.withValues(alpha: 0.6)
        : selected
            ? scheme.onPrimary
            : scheme.onSurface;
    final border = selected ? scheme.primary : scheme.outline;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: AppMotion.fast,
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.curve,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: widget.caption == null ? 10 : AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.pillAll,
            border: Border.all(color: border, width: selected ? 1.6 : 1),
            boxShadow: selected && enabled
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: AppMotion.normal,
                style: theme.textTheme.labelLarge!.copyWith(
                  fontSize: 14,
                  color: fg,
                ),
                child: Text(widget.label),
              ),
              if (widget.caption != null)
                AnimatedDefaultTextStyle(
                  duration: AppMotion.normal,
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: fg.withValues(alpha: 0.75),
                    letterSpacing: 0.2,
                  ),
                  child: Text(widget.caption!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
