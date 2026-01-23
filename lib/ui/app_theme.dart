import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF05070D);
  static const Color cardBackText = Color(0xFF0B1424);
  static const Color cardBackSubtitle = Color(0xFF20324D);
  static const Color cardBorderColor = Color(0xFFFFFFFF);
  static const Color shadowColor = Color(0x1F000000);

  static final ColorScheme colorScheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF4C8DFF),
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF0B1424),
        surfaceContainerHighest: const Color(0xFF1B2D4A),
        onSurface: const Color(0xFFF7F9FF),
        onSurfaceVariant: const Color(0xFFB9C7E6),
        outlineVariant: const Color(0xFF3A5580),
      );

  static final ThemeData theme = ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
  );
}
