import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Superficie base: fondo `surface`, radius de tarjeta y sombra suave.
/// Si se pasa `onTap` responde con escala al presionar.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final Gradient? gradient;
  final bool raised;
  final bool outlined;
  final BorderRadius? borderRadius;
  final Clip clipBehavior;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.onTap,
    this.onLongPress,
    this.color,
    this.gradient,
    this.raised = false,
    this.outlined = false,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = borderRadius ?? AppRadius.cardAll;

    final box = Container(
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? theme.colorScheme.surface) : null,
        gradient: gradient,
        borderRadius: radius,
        border: outlined
            ? Border.all(color: theme.colorScheme.outline)
            : null,
        boxShadow: raised
            ? AppShadows.raised(theme.brightness)
            : AppShadows.soft(theme.brightness),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null && onLongPress == null) return box;

    return _PressableCard(onTap: onTap, onLongPress: onLongPress, child: box);
  }
}

class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _PressableCard({required this.child, this.onTap, this.onLongPress});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
