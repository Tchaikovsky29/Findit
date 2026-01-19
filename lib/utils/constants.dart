import 'package:flutter/material.dart';

/// App Constants
/// Centralized location for all app-wide constants
/// Colors, padding, radius, text styles, etc.

class AppConstants {
  // ===== COLORS =====
  
  /// Primary brand color (Black)
  /// Used for buttons, AppBar, main UI elements
  static const Color primaryColor = Color(0xFF000000); // Black

  /// Secondary accent color (Dark Gray)
  /// Used for highlights, secondary actions
  static const Color secondaryColor = Color(0xFF333333); // Dark Gray

  /// Success/positive action color
  static const Color successColor = Color(0xFF10B981); // Green

  /// Error/negative action color
  static const Color errorColor = Color(0xFFEF4444); // Red

  /// Warning color
  static const Color warningColor = Color(0xFFF59E0B); // Amber

  /// Neutral/hint color
  static const Color hintColor = Color(0xFF666666); // Gray

  /// Background color (Black)
  static const Color backgroundColor = Color(0xFF000000);

  /// Surface color for cards, chips, etc. (Dark Gray)
  static const Color surfaceColor = Color(0xFF1E1E1E);

  /// Accent color (alias for secondary)
  static const Color accentColor = secondaryColor;
  
  // ===== PADDING =====
  
  static const double paddingXXLarge = 32.0;
  static const double paddingXLarge = 24.0;
  static const double paddingLarge = 16.0;
  static const double paddingMedium = 12.0;
  static const double paddingSmall = 8.0;
  static const double paddingXSmall = 4.0;
  
  // ===== BORDER RADIUS =====
  
  static const double radiusXLarge = 24.0;
  static const double radiusLarge = 16.0;
  static const double radiusMedium = 12.0;
  static const double radiusSmall = 8.0;
  static const double radiusXSmall = 4.0;
  
  // ===== TEXT STYLES =====
  
  /// Page title/headline style
  static const TextStyle headlineStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  /// Subheading style
  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white70,
  );

  /// Regular body text
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
  );

  /// Label style (buttons, form labels)
  static const TextStyle labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
  );

  /// Hint/secondary text style
  static const TextStyle hintStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xFF666666),
  );

  /// Body text style (alias for bodyStyle)
  static const TextStyle bodyText = bodyStyle;

  /// Heading 2 style (alias for subheadingStyle)
  static const TextStyle heading2 = subheadingStyle;

  /// Label text style (alias for labelStyle)
  static const TextStyle labelText = labelStyle;
  
  // ===== SHADOWS =====
  
  /// Standard shadow for elevated elements
  static const List<BoxShadow> standardShadow = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  /// Large shadow for prominent elements
  static const List<BoxShadow> largeShadow = [
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  // ===== ANIMATION DURATIONS =====
  
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // ===== OTHER CONSTANTS =====
  
  /// Max image file size in MB
  static const double maxImageSizeMB = 5;
  
  /// Min password length
  static const int minPasswordLength = 6;
  
  /// Max password length
  static const int maxPasswordLength = 32;
  
  /// PRN pattern (for validation)
  static const String prnPattern = r'^[A-Z]{2,3}\d{4,6}$';
  
  /// Email pattern (for validation)
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
}