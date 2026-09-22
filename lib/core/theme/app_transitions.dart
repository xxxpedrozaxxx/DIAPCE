import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Transición de página compartida: fade + desplazamiento sutil hacia arriba,
/// con la pantalla saliente atenuándose ligeramente. Se registra en
/// `ThemeData.pageTransitionsTheme`, así todos los `MaterialPageRoute`
/// existentes la usan sin cambiar las llamadas de navegación.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasized,
      reverseCurve: Curves.easeInCubic,
    );
    final fadeOut = Tween<double>(begin: 1, end: 0.92).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: fadeOut,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
    );
  }
}
