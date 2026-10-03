import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:docsmind/constants/app_constants.dart';

/// Material Design 3 (Material You) Theme Configuration for DocsMind.
///
/// Follows official M3 specification:
/// - Full 30+ token ColorScheme mapping for light and dark modes
/// - Typography scale using GoogleFonts (Inter)
/// - Component themes with stadium borders, tonal surfaces, and zero hardcoded colors
/// - Smooth predictive back motion and standard 8dp elevation/spacing hierarchy
class AppTheme {
  AppTheme._();

  // ── Light Color Scheme ───────────────────────────────────────────────────
  static final ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: const Color(0xFFBA1A1A),
    onError: Colors.white,
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF410002),
    surface: AppColors.lightBg,
    onSurface: AppColors.lightTextPrimary,
    onSurfaceVariant: AppColors.lightTextSecondary,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: AppColors.lightSurfaceContainerLow,
    surfaceContainer: AppColors.lightSurfaceContainer,
    surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
    surfaceContainerHighest: AppColors.lightSurfaceContainerHighest,
    outline: AppColors.lightOutline,
    outlineVariant: AppColors.lightOutlineVariant,
    shadow: Colors.transparent,
    scrim: Colors.black.withValues(alpha: 0.35),
    inverseSurface: const Color(0xFF313033),
    onInverseSurface: const Color(0xFFF4EFF4),
    inversePrimary: AppColors.primaryDark,
  );

  // ── Dark Color Scheme ────────────────────────────────────────────────────
  static final ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryDark,
    onPrimary: AppColors.onPrimaryDark,
    primaryContainer: AppColors.primaryContainerDark,
    onPrimaryContainer: AppColors.onPrimaryContainerDark,
    secondary: const Color(0xFFD7C2BA),
    onSecondary: const Color(0xFF3B2D27),
    secondaryContainer: const Color(0xFF52433C),
    onSecondaryContainer: const Color(0xFFF4DFD7),
    tertiary: const Color(0xFF6FD7D2),
    onTertiary: const Color(0xFF003735),
    tertiaryContainer: const Color(0xFF1F4E4C),
    onTertiaryContainer: AppColors.tertiaryContainer,
    error: const Color(0xFFFFB4AB),
    onError: const Color(0xFF690005),
    errorContainer: const Color(0xFF93000A),
    onErrorContainer: const Color(0xFFFFDAD6),
    surface: AppColors.darkBg,
    onSurface: AppColors.darkTextPrimary,
    onSurfaceVariant: AppColors.darkTextSecondary,
    surfaceContainerLowest: const Color(0xFF0F0B0A),
    surfaceContainerLow: AppColors.darkSurfaceContainerLow,
    surfaceContainer: AppColors.darkSurfaceContainer,
    surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
    surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkOutlineVariant,
    shadow: Colors.transparent,
    scrim: Colors.black.withValues(alpha: 0.6),
    inverseSurface: const Color(0xFFE6E1E5),
    onInverseSurface: const Color(0xFF313033),
    inversePrimary: AppColors.primary,
  );

  // ── Text Theme Generator ─────────────────────────────────────────────────
  static TextTheme _buildTextTheme(TextTheme base, Color textColor, Color secondaryColor) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.newsreader(
        fontSize: 57,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: textColor,
      ),
      displayMedium: GoogleFonts.newsreader(
        fontSize: 45,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
      ),
      displaySmall: GoogleFonts.newsreader(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.newsreader(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.newsreader(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.newsreader(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: textColor,
      ),
      titleLarge: GoogleFonts.newsreader(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: textColor,
      ),
      titleMedium: GoogleFonts.newsreader(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.15,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: secondaryColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05,
        color: textColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.05,
        color: secondaryColor,
      ),
    );
  }

  // ── M3 Shared Page Transitions ───────────────────────────────────────────
  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
    },
  );

  // ── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final cs = lightColorScheme;
    final textTheme = _buildTextTheme(
      ThemeData.light().textTheme,
      cs.onSurface,
      cs.onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      textTheme: textTheme,
      pageTransitionsTheme: _pageTransitions,
      splashColor: cs.primary.withValues(alpha: 0.08),
      highlightColor: cs.primary.withValues(alpha: 0.04),

      // App Bar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: cs.onSurface),
      ),

      // Navigation Bar (Mobile Bottom)
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        elevation: 0,
        backgroundColor: cs.surfaceContainerLowest,
        indicatorColor: cs.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          );
        }),
      ),

      // Navigation Rail (Tablet / Desktop Wide screens)
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cs.surfaceContainer,
        indicatorColor: cs.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onPrimaryContainer,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
        ),
        selectedIconTheme: IconThemeData(color: cs.onPrimaryContainer, size: 24),
        unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant, size: 24),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.surfaceContainerLow,
          foregroundColor: cs.primary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: cs.outlineVariant, width: 1.0),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
        pressElevation: 0,
        shadowColor: Colors.transparent,
        side: BorderSide(color: cs.outlineVariant),
        backgroundColor: cs.surfaceContainer,
        selectedColor: cs.primaryContainer,
        showCheckmark: false,
        labelStyle: textTheme.labelMedium,
      ),

      // Segmented Button
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          selectedBackgroundColor: cs.primaryContainer,
          selectedForegroundColor: cs.onPrimaryContainer,
          backgroundColor: cs.surfaceContainer,
          foregroundColor: cs.onSurfaceVariant,
          side: BorderSide(color: cs.outlineVariant),
          textStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // Cards
      cardTheme: CardTheme(
        color: cs.surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant, width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Bottom Sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: cs.outline,
      ),

      // Dialogs
      dialogTheme: DialogTheme(
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // SnackBars
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: cs.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: cs.onInverseSurface,
        ),
      ),

      // Search Bar
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerLowest),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: cs.outlineVariant, width: 1.0),
        ),
        textStyle: WidgetStatePropertyAll(
          textTheme.bodyLarge?.copyWith(color: cs.onSurface),
        ),
        hintStyle: WidgetStatePropertyAll(
          textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ),

      // Text Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.error),
        ),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // List Tiles
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconColor: cs.onSurfaceVariant,
        textColor: cs.onSurface,
      ),
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final cs = darkColorScheme;
    final textTheme = _buildTextTheme(
      ThemeData.dark().textTheme,
      cs.onSurface,
      cs.onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      textTheme: textTheme,
      pageTransitionsTheme: _pageTransitions,
      splashColor: cs.primary.withValues(alpha: 0.08),
      highlightColor: cs.primary.withValues(alpha: 0.04),

      // App Bar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: cs.onSurface),
      ),

      // Navigation Bar (Mobile Bottom)
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        elevation: 0,
        backgroundColor: cs.surfaceContainer,
        indicatorColor: cs.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          );
        }),
      ),

      // Navigation Rail (Tablet / Desktop Wide screens)
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cs.surfaceContainer,
        indicatorColor: cs.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onPrimaryContainer,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
        ),
        selectedIconTheme: IconThemeData(color: cs.onPrimaryContainer, size: 24),
        unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant, size: 24),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.surfaceContainerLow,
          foregroundColor: cs.primary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: cs.outlineVariant, width: 1.0),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
        pressElevation: 0,
        shadowColor: Colors.transparent,
        side: BorderSide(color: cs.outlineVariant),
        backgroundColor: cs.surfaceContainer,
        selectedColor: cs.primaryContainer,
        showCheckmark: false,
        labelStyle: textTheme.labelMedium,
      ),

      // Segmented Button
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          selectedBackgroundColor: cs.primaryContainer,
          selectedForegroundColor: cs.onPrimaryContainer,
          backgroundColor: cs.surfaceContainer,
          foregroundColor: cs.onSurfaceVariant,
          side: BorderSide(color: cs.outlineVariant),
          textStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // Cards
      cardTheme: CardTheme(
        color: cs.surfaceContainerLow,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant, width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Bottom Sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: cs.outline,
      ),

      // Dialogs
      dialogTheme: DialogTheme(
        backgroundColor: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // SnackBars
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: cs.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: cs.onInverseSurface,
        ),
      ),

      // Search Bar
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainer),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: cs.outlineVariant, width: 1.0),
        ),
        textStyle: WidgetStatePropertyAll(
          textTheme.bodyLarge?.copyWith(color: cs.onSurface),
        ),
        hintStyle: WidgetStatePropertyAll(
          textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ),

      // Text Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.error),
        ),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // List Tiles
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconColor: cs.onSurfaceVariant,
        textColor: cs.onSurface,
      ),
    );
  }
}
