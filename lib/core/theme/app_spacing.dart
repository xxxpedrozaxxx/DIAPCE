import 'package:flutter/material.dart';

/// Escala de espaciado (múltiplos de 4) usada en toda la app.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Padding horizontal estándar de pantalla.
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets card = EdgeInsets.all(md);
}

/// Radios de borde. `base` para inputs y botones, `card` para tarjetas,
/// `pill` para chips.
class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double base = 16;
  static const double card = 20;
  static const double lg = 28;
  static const double pill = 999;

  static BorderRadius get baseAll => BorderRadius.circular(base);
  static BorderRadius get cardAll => BorderRadius.circular(card);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
}

/// Sombras sutiles (nada de elevation Material por defecto).
class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft(Brightness brightness) => [
        BoxShadow(
          color: brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.35)
              : const Color(0xFF1B2C8F).withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> raised(Brightness brightness) => [
        BoxShadow(
          color: brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.5)
              : const Color(0xFF1B2C8F).withValues(alpha: 0.12),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];
}

/// Duraciones y curvas de animación compartidas.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 450);
  static const Curve curve = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;
}
