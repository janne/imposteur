import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF05070D);
  static const Color panelSurface = Color(0xFF0B1424);
  static const Color panelSurfaceDeep = Color(0xFF07101F);
  static const Color cardBackText = Color(0xFF0B1424);
  static const Color cardBackSubtitle = Color(0xFF20324D);
  static const Color cardBorderColor = Color(0xFFFFFFFF);
  static const Color shadowColor = Color(0x1F000000);
  static const Color neonCyan = Color(0xFF5CF0FF);
  static const Color neonMint = Color(0xFF6CF6C2);
  static const Color neonRed = Color(0xFFFF4D5A);
  static const Color neonOrange = Color(0xFFFF8A52);

  static final ColorScheme colorScheme =
      ColorScheme.fromSeed(
        seedColor: neonCyan,
        brightness: Brightness.dark,
      ).copyWith(
        primary: neonCyan,
        secondary: neonMint,
        surface: panelSurface,
        surfaceContainerHighest: const Color(0xFF13223B),
        onSurface: const Color(0xFFF7F9FF),
        onSurfaceVariant: const Color(0xFFB9C7E6),
        outlineVariant: const Color(0xFF294464),
      );

  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    textTheme: GoogleFonts.exo2TextTheme().apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
    ),
  );
}
