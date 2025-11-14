import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional corporate theme for enterprise application
/// - Subtle colors, not overwhelming
/// - Clean and modern UI
/// - Accessible contrast ratios
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Corporate Color Palette - Sophisticated & Professional
  static const Color _primaryBlue = Color(0xFF1E3A8A); // Deep professional blue
  static const Color _secondaryBlue = Color(0xFF3B82F6); // Bright blue for accents
  static const Color _lightBlue = Color(0xFFEFF6FF); // Very light blue for backgrounds

  static const Color _neutral900 = Color(0xFF111827); // Almost black for text
  static const Color _neutral700 = Color(0xFF374151); // Dark gray for secondary text
  static const Color _neutral500 = Color(0xFF6B7280); // Medium gray
  static const Color _neutral300 = Color(0xFFD1D5DB); // Light gray for borders
  static const Color _neutral100 = Color(0xFFF3F4F6); // Very light gray
  static const Color _neutral50 = Color(0xFFF9FAFB); // Off-white

  // Status Colors - Subtle but clear
  static const Color _success = Color(0xFF10B981); // Green
  static const Color _warning = Color(0xFFF59E0B); // Amber
  static const Color _error = Color(0xFFEF4444); // Red
  static const Color _info = Color(0xFF3B82F6); // Blue

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: _primaryBlue,
      secondary: _secondaryBlue,
      tertiary: _neutral700,
      surface: Colors.white,
      background: _neutral50,
      error: _error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _neutral900,
      onBackground: _neutral900,
      onError: Colors.white,
      outline: _neutral300,
    ),

    // Scaffold
    scaffoldBackgroundColor: _neutral50,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: _neutral900,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _neutral900,
        letterSpacing: -0.5,
      ),
      iconTheme: const IconThemeData(
        color: _neutral700,
        size: 24,
      ),
    ),

    // Cards
    cardTheme: CardTheme(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: _neutral300,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.all(0),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _neutral300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _neutral300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _error, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _neutral700,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: _neutral500,
      ),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _neutral900,
        side: const BorderSide(color: _neutral300),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryBlue,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Icon Button
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: _neutral700,
        hoverColor: _neutral100,
      ),
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: _neutral100,
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _neutral700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: _neutral300,
      thickness: 1,
      space: 1,
    ),

    // Text Theme
    textTheme: GoogleFonts.interTextTheme(
      TextTheme(
        // Display styles
        displayLarge: GoogleFonts.inter(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          color: _neutral900,
          letterSpacing: -1.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          color: _neutral900,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: _neutral900,
        ),

        // Headline styles
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: _neutral900,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: _neutral900,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: _neutral900,
        ),

        // Title styles
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _neutral900,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _neutral900,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _neutral900,
        ),

        // Body styles
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _neutral900,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _neutral900,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: _neutral700,
        ),

        // Label styles
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _neutral900,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _neutral700,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _neutral700,
        ),
      ),
    ),

    // Data Table
    dataTableTheme: DataTableThemeData(
      headingRowColor: MaterialStateProperty.all(_neutral100),
      dataRowColor: MaterialStateProperty.all(Colors.white),
      decoration: BoxDecoration(
        border: Border.all(color: _neutral300),
        borderRadius: BorderRadius.circular(8),
      ),
      headingTextStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _neutral900,
      ),
      dataTextStyle: GoogleFonts.inter(
        fontSize: 14,
        color: _neutral900,
      ),
    ),

    // Popup Menu
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _neutral300),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        color: _neutral900,
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: _primaryBlue,
      unselectedItemColor: _neutral500,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Drawer
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.white,
      elevation: 8,
    ),
  );

  // Status colors for badges and indicators
  static Color get successColor => _success;
  static Color get warningColor => _warning;
  static Color get errorColor => _error;
  static Color get infoColor => _info;

  // Neutral colors for components
  static Color get neutral900 => _neutral900;
  static Color get neutral700 => _neutral700;
  static Color get neutral500 => _neutral500;
  static Color get neutral300 => _neutral300;
  static Color get neutral100 => _neutral100;
  static Color get neutral50 => _neutral50;

  // Primary colors
  static Color get primaryBlue => _primaryBlue;
  static Color get secondaryBlue => _secondaryBlue;
  static Color get lightBlue => _lightBlue;
}
