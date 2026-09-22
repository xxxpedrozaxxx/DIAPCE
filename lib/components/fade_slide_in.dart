import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Entrada con fade + desplazamiento. `index` escalona el retardo para
/// listas y grids (stagger). Solo anima una vez, al montarse.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;
  final Offset beginOffset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delayPerItem = const Duration(milliseconds: 60),
    this.duration = AppMotion.slow,
    this.beginOffset = const Offset(0, 0.08),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: AppMotion.emphasized);
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero).animate(curved);

    final delay = widget.delayPerItem * widget.index.clamp(0, 12);
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
