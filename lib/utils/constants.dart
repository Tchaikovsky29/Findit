import 'package:flutter/material.dart';

/// App-wide constants for colors, sizes, and strings
class AppConstants {
  // ===== COLORS =====
  static const Color primaryColor = Color(0xFF6200EA);      // Deep Purple
  static const Color accentColor = Color(0xFF03DAC6);       // Teal
  static const Color errorColor = Color(0xFFB3261E);        // Red
  static const Color successColor = Color(0xFF4CAF50);      // Green
  static const Color backgroundColor = Color(0xFFFAFBFC);   // Off-white
  static const Color surfaceColor = Color(0xFFFFFFFF);      // White
  static const Color textColor = Color(0xFF1C1B1F);         // Dark text
  static const Color hintColor = Color(0xFF79747E);         // Hint text

  // ===== PADDING/MARGINS (8-point grid system) =====
  static const double paddingXSmall = 4.0;    // âœ… ADDED
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;   // âœ… ADDED - This was missing!
  static const double paddingXXLarge = 48.0;  // âœ… ADDED - Extra large

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

  // ===== APP STRINGS =====
  static const String appName = 'Find-It';
  static const String appTagline = 'Lost & Found, Made Easy';
  static const String loginTitle = 'Welcome Back';
  static const String loginSubtitle = 'Sign in to your account';
  static const String registerTitle = 'Create Account';
  static const String registerSubtitle = 'Join our community';
}