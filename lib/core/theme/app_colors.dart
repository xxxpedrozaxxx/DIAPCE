import 'package:flutter/material.dart';

/// Paleta monocromática de DIAPCE.
///
/// Un solo tono dominante (cobalto) con variaciones tonales, un acento cálido
/// usado con moderación y neutros fríos para fondo/superficie. Inspirado en el
/// principio "un color, muchas intensidades" de la referencia AirPods.
class AppColors {
  AppColors._();

  // ── Primario (cobalto) ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF2E4FD8);
  static const Color primaryDark = Color(0xFF1B2C8F);
  static const Color primaryLight = Color(0xFF6B84F2);
  static const Color primaryContainer = Color(0xFFE3E8FF);
  static const Color primarySoft = Color(0xFFF0F3FF);

  // ── Acento (ámbar, uso puntual: badges, highlights) ─────────────────────
  static const Color accent = Color(0xFFF5A524);
  static const Color accentContainer = Color(0xFFFFF1D6);

  // ── Neutros claros ──────────────────────────────────────────────────────
  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEF0F6);
  static const Color outline = Color(0xFFD9DDEA);
  static const Color textPrimary = Color(0xFF101426);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFFA6ABBD);

  // ── Neutros oscuros ─────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0D1020);
  static const Color surfaceDark = Color(0xFF161A2E);
  static const Color surfaceVariantDark = Color(0xFF1F2440);
  static const Color outlineDark = Color(0xFF2E3454);
  static const Color textPrimaryDark = Color(0xFFF2F3F8);
  static const Color textSecondaryDark = Color(0xFF9AA0B8);
  static const Color textDisabledDark = Color(0xFF5B617A);

  // ── Estados ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);

  // ── Series para gráficas (tonos del primario + acento) ──────────────────
  static const List<Color> chartSeries = [
    Color(0xFF2E4FD8),
    Color(0xFF6B84F2),
    Color(0xFFF5A524),
    Color(0xFF4F63B8),
    Color(0xFFA5B4FB),
    Color(0xFFFFC96B),
    Color(0xFF8FA3FF),
    Color(0xFFC7D0FF),
  ];

  // ── Degradados suaves ───────────────────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D5EF0), Color(0xFF1B2C8F)],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE3E8FF), Color(0xFFF6F7FB)],
  );

  static const LinearGradient softGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1F2440), Color(0xFF0D1020)],
  );
}
