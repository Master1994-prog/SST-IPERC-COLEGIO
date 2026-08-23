import 'package:flutter/material.dart';

/// ===============================================================
/// COLORES SST EDURISK
/// ===============================================================
///
/// Paleta obtenida de la identidad visual del logotipo.
///
/// Azul oscuro  -> identidad principal.
/// Azul vivo    -> elementos activos.
/// Verde        -> estados seguros / correctos.
/// Amarillo     -> advertencias.
/// Rojo/naranja -> riesgo crítico / errores.
/// ===============================================================
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF083F85);

  static const Color primaryBright = Color(0xFF0D60D6);

  static const Color navyDark = Color(0xFF05295E);

  static const Color green = Color(0xFF1DA041);

  static const Color yellow = Color(0xFFFEB81C);

  static const Color riskOrange = Color(0xFFEC490F);

  static const Color background = Color(0xFFF6F8FC);

  static const Color surface = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFD5DCE8);

  static const Color textPrimary = Color(0xFF172033);

  static const Color textSecondary = Color(0xFF5E687A);
}

/// ===============================================================
/// TEMA SST EDURISK
/// ===============================================================
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,

      primaryContainer: Color(0xFFDCEAFF),
      onPrimaryContainer: AppColors.navyDark,

      secondary: AppColors.primaryBright,
      onSecondary: Colors.white,

      secondaryContainer: Color(0xFFDDEBFF),
      onSecondaryContainer: AppColors.navyDark,

      tertiary: AppColors.green,
      onTertiary: Colors.white,

      tertiaryContainer: Color(0xFFDDF4E3),
      onTertiaryContainer: Color(0xFF075722),

      error: AppColors.riskOrange,
      onError: Colors.white,

      errorContainer: Color(0xFFFFE2D8),
      onErrorContainer: Color(0xFF701F07),

      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,

      outline: Color(0xFF758195),
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,

      colorScheme: colorScheme,

      scaffoldBackgroundColor: AppColors.background,

      // =========================================================
      // APP BAR
      // =========================================================
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // =========================================================
      // NAVIGATION BAR
      // =========================================================
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,

        indicatorColor: AppColors.primaryBright.withValues(alpha: 0.14),

        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 27);
          }

          return const IconThemeData(color: AppColors.textSecondary, size: 25);
        }),

        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            );
          }

          return const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),

      // =========================================================
      // BOTONES
      // =========================================================
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primaryBright),
      ),

      // =========================================================
      // CAMPOS
      // =========================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,

        labelStyle: const TextStyle(color: AppColors.textSecondary),

        prefixIconColor: AppColors.primary,

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primaryBright,
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.riskOrange),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.riskOrange, width: 2),
        ),
      ),

      // =========================================================
      // CARDS
      // =========================================================
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: AppColors.primary.withValues(alpha: 0.10),
        surfaceTintColor: Colors.transparent,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // =========================================================
      // CHIPS
      // =========================================================
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEAF1FB),
        selectedColor: const Color(0xFFDCEAFF),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // =========================================================
      // DIVISORES
      // =========================================================
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE4E8F0),
        thickness: 1,
      ),

      // =========================================================
      // PROGRESS
      // =========================================================
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryBright,
        linearTrackColor: Color(0xFFDCEAFF),
      ),

      // =========================================================
      // SNACKBAR
      // =========================================================
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navyDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
