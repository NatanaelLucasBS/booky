import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Configuração do Design System e Temas (Light e Dark) do BOOKY.
/// Utiliza exclusivamente a paleta de 5 tons e estética editorial.
abstract final class AppTheme {
  static const List<String> serifFontFamilyFallback = ['Georgia', 'Times New Roman', 'serif'];
  static const List<String> sansFontFamilyFallback = ['Helvetica Neue', 'Arial', 'sans-serif'];

  // ==========================================
  // TEMA CLARO (LIGHT THEME)
  // ==========================================
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.darkBrown,
      onPrimary: AppColors.lightCream,
      primaryContainer: AppColors.darkBrown,
      onPrimaryContainer: AppColors.lightCream,
      secondary: AppColors.woodBrown,
      onSecondary: AppColors.lightCream,
      secondaryContainer: AppColors.beige,
      onSecondaryContainer: AppColors.darkBrown,
      tertiary: AppColors.mediumBrown,
      onTertiary: AppColors.lightCream,
      surface: AppColors.lightCream,
      onSurface: AppColors.darkBrown,
      surfaceContainerHighest: AppColors.beige,
      onSurfaceVariant: AppColors.woodBrown,
      outline: AppColors.beige,
      outlineVariant: AppColors.beige,
      error: AppColors.darkBrown,
      onError: AppColors.lightCream,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightCream,
      colorScheme: colorScheme,
      canvasColor: AppColors.lightCream,
      dividerColor: AppColors.beige,
      splashFactory: InkRipple.splashFactory,

      // Tipografia Editorial
      textTheme: const TextTheme(
        // Serif para Títulos e Destaques
        displayLarge: TextStyle(
          fontFamilyFallback: serifFontFamilyFallback,
          fontSize: 40,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: AppColors.darkBrown,
          height: 1.15,
        ),
        headlineLarge: TextStyle(
          fontFamilyFallback: serifFontFamilyFallback,
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: AppColors.darkBrown,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontFamilyFallback: serifFontFamilyFallback,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: AppColors.darkBrown,
          height: 1.25,
        ),
        headlineSmall: TextStyle(
          fontFamilyFallback: serifFontFamilyFallback,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkBrown,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontFamilyFallback: serifFontFamilyFallback,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkBrown,
        ),
        titleMedium: TextStyle(
          fontFamilyFallback: serifFontFamilyFallback,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.darkBrown,
        ),

        // Sans-Serif para Leitura, Informações e Rótulos
        bodyLarge: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.darkBrown,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.woodBrown,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.mediumBrown,
          height: 1.3,
        ),
        labelLarge: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
          color: AppColors.darkBrown,
        ),
        labelMedium: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: AppColors.woodBrown,
        ),
        labelSmall: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: AppColors.mediumBrown,
        ),
      ),

      // AppBar Editorial
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightCream,
        foregroundColor: AppColors.darkBrown,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamilyFallback: serifFontFamilyFallback,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkBrown,
        ),
        iconTheme: IconThemeData(
          color: AppColors.darkBrown,
          size: 22,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightCream,
        selectedItemColor: AppColors.darkBrown,
        unselectedItemColor: AppColors.mediumBrown,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
        selectedLabelStyle: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),

      // Card Theme com borda sutil
      cardTheme: CardThemeData(
        color: AppColors.lightCream,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.beige, width: 1.0),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          color: AppColors.mediumBrown,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.beige, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.darkBrown, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.woodBrown, width: 1.0),
        ),
      ),

      // Botões Primários
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkBrown,
          foregroundColor: AppColors.lightCream,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontFamilyFallback: sansFontFamilyFallback,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),

      // Botões Secundários / Outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkBrown,
          side: const BorderSide(color: AppColors.beige, width: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontFamilyFallback: sansFontFamilyFallback,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),

      // Divisores
      dividerTheme: const DividerThemeData(
        color: AppColors.beige,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }

  // ==========================================
  // TEMA ESCURO (DARK THEME)
  // ==========================================
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.lightCream,
      onPrimary: AppColors.darkBrown,
      primaryContainer: AppColors.woodBrown,
      onPrimaryContainer: AppColors.lightCream,
      secondary: AppColors.beige,
      onSecondary: AppColors.darkBrown,
      secondaryContainer: AppColors.mediumBrown,
      onSecondaryContainer: AppColors.lightCream,
      tertiary: AppColors.mediumBrown,
      onTertiary: AppColors.lightCream,
      surface: AppColors.darkBrown,
      onSurface: AppColors.lightCream,
      surfaceContainerHighest: AppColors.woodBrown,
      onSurfaceVariant: AppColors.beige,
      outline: AppColors.mediumBrown,
      outlineVariant: AppColors.woodBrown,
      error: AppColors.beige,
      onError: AppColors.darkBrown,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBrown,
      colorScheme: colorScheme,
      canvasColor: AppColors.darkBrown,
      dividerColor: AppColors.woodBrown,
      splashFactory: InkRipple.splashFactory,

      // Tipografia Editorial Dark
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamilyFallback: serifFontFamilyFallback,
          fontSize: 40,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: AppColors.lightCream,
          height: 1.15,
        ),
        headlineLarge: TextStyle(
          fontFamilyFallback: serifFontFamilyFallback,
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: AppColors.lightCream,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontFamilyFallback: serifFontFamilyFallback,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: AppColors.lightCream,
          height: 1.25,
        ),
        headlineSmall: TextStyle(
          fontFamilyFallback: serifFontFamilyFallback,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.lightCream,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontFamilyFallback: serifFontFamilyFallback,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.lightCream,
        ),
        titleMedium: TextStyle(
          fontFamilyFallback: serifFontFamilyFallback,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.lightCream,
        ),
        bodyLarge: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.lightCream,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.beige,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.beige,
          height: 1.3,
        ),
        labelLarge: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
          color: AppColors.lightCream,
        ),
        labelMedium: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: AppColors.beige,
        ),
        labelSmall: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: AppColors.beige,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBrown,
        foregroundColor: AppColors.lightCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamilyFallback: serifFontFamilyFallback,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.lightCream,
        ),
        iconTheme: IconThemeData(
          color: AppColors.lightCream,
          size: 22,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkBrown,
        selectedItemColor: AppColors.lightCream,
        unselectedItemColor: AppColors.mediumBrown,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
        selectedLabelStyle: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.woodBrown,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.mediumBrown, width: 1.0),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(
          fontFamilyFallback: sansFontFamilyFallback,
          color: AppColors.beige,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.mediumBrown, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.lightCream, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.beige, width: 1.0),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightCream,
          foregroundColor: AppColors.darkBrown,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontFamilyFallback: sansFontFamilyFallback,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightCream,
          side: const BorderSide(color: AppColors.mediumBrown, width: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontFamilyFallback: sansFontFamilyFallback,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.woodBrown,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }
}
