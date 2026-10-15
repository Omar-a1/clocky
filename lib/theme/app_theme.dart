import 'package:flutter/material.dart';

/// Google Clock / Material You (M3) Dark Theme Constants & Tokens
class AppTheme {
  // Theme Backgrounds & Surfaces
  static const Color darkBackground = Color(0xFF0E1B18); // Deep Dark Green/Teal
  static const Color cardColor = Color(0xFF1A2B27);       // Subtle rounded filled background
  static const Color cardColorInactive = Color(0xFF14221F);

  // Material You / Accent Colors
  static const Color seedColor = Color(0xFF006A60);
  static const Color activeAccent = Color(0xFF4EEAD8);    // Soft teal / cyan
  static const Color activeAccentMuted = Color(0xFF86F8E8);
  static const Color activeContainer = Color(0xFF005048);
  static const Color onActiveContainer = Color(0xFF8EF2E4);

  // Neutral tones
  static const Color textPrimary = Color(0xFFE1E3DF);
  static const Color textSecondary = Color(0xFF89938F);
  static const Color sectionHeader = Color(0xFF80CEC2);

  // Navigation Bar tokens
  static const Color navBarBackground = Color(0xFF131F1C);
  static const Color navBarIndicator = Color(0xFF1F4E46);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: seedColor,
      scaffoldBackgroundColor: darkBackground,
      canvasColor: darkBackground,
      cardColor: cardColor,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF003731);
          }
          return const Color(0xFF89938F);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return activeAccent;
          }
          return const Color(0xFF283B37);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return const Color(0xFF4A5C57);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: activeAccent,
        foregroundColor: const Color(0xFF003731),
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22), // M3 squircle FAB
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarBackground,
        elevation: 0,
        indicatorColor: navBarIndicator,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: activeAccent,
              size: 26,
            );
          }
          return const IconThemeData(
            color: textSecondary,
            size: 26,
          );
        }),
      ),
    );
  }
}
