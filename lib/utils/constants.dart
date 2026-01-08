import 'package:flutter/material.dart';

class AppConstants {
  // ===== COLORS =====
  static const Color primaryColor = Color(0xFF6200EA);
  static const Color accentColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB3261E);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFFAFBFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1C1B1F);
  static const Color hintColor = Color(0xFF79747E);

  // ===== PADDING =====
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  static const double paddingXXLarge = 48.0;

  // ===== BORDER RADIUS =====
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;

  // ===== TEXT STYLES =====
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textColor,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textColor,
  );

  static const TextStyle labelText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textColor,
  );

  // ===== STRINGS =====
  static const String appName = 'Find-It';
  static const String appTagline = 'Lost & Found, Made Easy';
}
