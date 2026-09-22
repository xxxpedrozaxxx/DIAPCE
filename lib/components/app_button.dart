import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

enum AppButtonVariant { filled, outline, text, tonal }

/// Botón de la app con variantes filled / outline / text / tonal,
/// estado de carga, disabled y escala al presionar.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.color,
  });

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.color,
  }) : variant = AppButtonVariant.outline;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.color,
  }) : variant = AppButtonVariant.text;

  const AppButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.color,
  }) : variant = AppButtonVariant.tonal;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Widget content = widget.loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: widget.variant == AppButtonVariant.filled
                  ? scheme.onPrimary
                  : scheme.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(widget.label),
            ],
          );

    final onPressed = _enabled ? widget.onPressed : null;

    Widget button;
    switch (widget.variant) {
      case AppButtonVariant.filled:
        button = FilledButton(
          onPressed: onPressed,
          style: widget.color == null
              ? null
              : FilledButton.styleFrom(backgroundColor: widget.color),
          child: content,
        );
      case AppButtonVariant.tonal:
        button = FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: widget.color ?? scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
          ),
          child: content,
        );
      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: onPressed,
          style: widget.color == null
              ? null
              : OutlinedButton.styleFrom(
                  foregroundColor: widget.color,
                  side: BorderSide(color: widget.color!, width: 1.4),
                ),
          child: content,
        );
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: onPressed,
          style: widget.color == null
              ? null
              : TextButton.styleFrom(foregroundColor: widget.color),
          child: content,
        );
    }

    if (widget.expand) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return Listener(
      onPointerDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: _enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel:
          _enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        child: button,
      ),
    );
  }
}
