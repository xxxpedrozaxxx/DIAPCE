import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_transitions.dart';

/// ThemeData global de DIAPCE (claro y oscuro).
///
/// Todo estilo de componente vive aquí; las pantallas no deben hardcodear
/// colores ni tamaños de fuente, solo consumir `Theme.of(context)`.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  // ── ColorScheme ─────────────────────────────────────────────────────────

  static ColorScheme _scheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.primaryLight : AppColors.primary,
      onPrimary: isDark ? AppColors.backgroundDark : Colors.white,
      primaryContainer:
          isDark ? AppColors.surfaceVariantDark : AppColors.primaryContainer,
      onPrimaryContainer:
          isDark ? AppColors.textPrimaryDark : AppColors.primaryDark,
      secondary: AppColors.accent,
      onSecondary: AppColors.textPrimary,
      secondaryContainer:
          isDark ? const Color(0xFF3A2E12) : AppColors.accentContainer,
      onSecondaryContainer:
          isDark ? AppColors.accentContainer : const Color(0xFF7A4B00),
      tertiary: AppColors.success,
      onTertiary: Colors.white,
      tertiaryContainer:
          isDark ? const Color(0xFF12331F) : AppColors.successContainer,
      onTertiaryContainer:
          isDark ? AppColors.successContainer : const Color(0xFF14532D),
      error: AppColors.error,
      onError: Colors.white,
      errorContainer:
          isDark ? const Color(0xFF3B1414) : AppColors.errorContainer,
      onErrorContainer:
          isDark ? AppColors.errorContainer : const Color(0xFF7F1D1D),
      surface: isDark ? AppColors.surfaceDark : AppColors.surface,
      onSurface: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      surfaceContainerHighest:
          isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
      surfaceContainerLow:
          isDark ? AppColors.backgroundDark : AppColors.background,
      onSurfaceVariant:
          isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
      outline: isDark ? AppColors.outlineDark : AppColors.outline,
      outlineVariant: isDark ? AppColors.outlineDark : AppColors.surfaceVariant,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? AppColors.surface : AppColors.textPrimary,
      onInverseSurface: isDark ? AppColors.textPrimary : AppColors.surface,
      inversePrimary: isDark ? AppColors.primary : AppColors.primaryLight,
    );
  }

  // ── TextTheme (Manrope) ─────────────────────────────────────────────────

  static TextTheme _textTheme(ColorScheme scheme) {
    final onSurface = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;
    final base = GoogleFonts.manropeTextTheme();

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 40, fontWeight: FontWeight.w800, height: 1.05,
        letterSpacing: -1.2, color: onSurface,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 32, fontWeight: FontWeight.w800, height: 1.1,
        letterSpacing: -0.8, color: onSurface,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 28, fontWeight: FontWeight.w800, height: 1.15,
        letterSpacing: -0.6, color: onSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24, fontWeight: FontWeight.w700, height: 1.2,
        letterSpacing: -0.4, color: onSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 20, fontWeight: FontWeight.w700, height: 1.25,
        letterSpacing: -0.2, color: onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18, fontWeight: FontWeight.w700, color: onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16, fontWeight: FontWeight.w600, color: onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14, fontWeight: FontWeight.w600, color: onSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, color: onSurface,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14, fontWeight: FontWeight.w500, height: 1.5, color: onSurface,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12, fontWeight: FontWeight.w500, height: 1.4, color: muted,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1,
        color: onSurface,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 13, fontWeight: FontWeight.w600, color: muted,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6,
        color: muted,
      ),
    );
  }

  // ── ThemeData ───────────────────────────────────────────────────────────

  static ThemeData _build(Brightness brightness) {
    final scheme = _scheme(brightness);
    final text = _textTheme(scheme);
    final isDark = brightness == Brightness.dark;
    final background =
        isDark ? AppColors.backgroundDark : AppColors.background;

    final inputBorder = OutlineInputBorder(
      borderRadius: AppRadius.baseAll,
      borderSide: BorderSide(color: scheme.outline),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: AppColors.surfaceDark,
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: AppColors.surface,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: _buttonBase(scheme, text).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.surfaceContainerHighest;
            }
            if (states.contains(WidgetState.pressed)) {
              return isDark ? AppColors.primary : AppColors.primaryDark;
            }
            return scheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return isDark ? AppColors.textDisabledDark : AppColors.textDisabled;
            }
            return scheme.onPrimary;
          }),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonBase(scheme, text).copyWith(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.surfaceContainerHighest;
            }
            if (states.contains(WidgetState.pressed)) {
              return isDark ? AppColors.primary : AppColors.primaryDark;
            }
            return scheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return isDark ? AppColors.textDisabledDark : AppColors.textDisabled;
            }
            return scheme.onPrimary;
          }),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonBase(scheme, text).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return scheme.primary.withValues(alpha: 0.08);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return isDark ? AppColors.textDisabledDark : AppColors.textDisabled;
            }
            return scheme.onSurface;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: scheme.outline);
            }
            return BorderSide(color: scheme.onSurface, width: 1.4);
          }),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.baseAll),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.baseAll),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.8),
        ),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: text.labelMedium?.copyWith(color: scheme.primary),
        hintStyle: text.bodyMedium?.copyWith(
          color: isDark ? AppColors.textDisabledDark : AppColors.textDisabled,
        ),
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return scheme.primary;
          if (states.contains(WidgetState.error)) return scheme.error;
          return scheme.onSurfaceVariant;
        }),
        suffixIconColor: scheme.onSurfaceVariant,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary,
        disabledColor: scheme.surfaceContainerHighest,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        labelStyle: text.labelMedium?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: scheme.onPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2,
        ),
        showCheckmark: false,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant, thickness: 1, space: 1,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        showDragHandle: true,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.baseAll),
        insetPadding: const EdgeInsets.all(AppSpacing.md),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadius.lg)),
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.baseAll),
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        iconColor: scheme.onSurfaceVariant,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: text.labelSmall,
        unselectedLabelStyle: text.labelSmall,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.primaryContainer,
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        headerHeadlineStyle: text.headlineMedium,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: text.bodyMedium,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.baseAll),
          ),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
    );
  }

  static ButtonStyle _buttonBase(ColorScheme scheme, TextTheme text) {
    return ButtonStyle(
      textStyle: WidgetStatePropertyAll(text.labelLarge),
      minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadius.baseAll),
      ),
      overlayColor: WidgetStatePropertyAll(
        scheme.onSurface.withValues(alpha: 0.06),
      ),
      animationDuration: AppMotion.fast,
    );
  }
}

/// Atajos de acceso a tokens desde cualquier `BuildContext`.
extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
