import '../../env.dart';

/// Secure configuration loader
/// Handles all credentials safely at runtime
class AppConfig {
  // ===== SUPABASE =====
  static String get supabaseUrl => EnvironmentConfig.supabaseUrl;
  static String get supabaseAnonKey => EnvironmentConfig.supabaseAnonKey;
  static String get supabaseAdminKey => EnvironmentConfig.supabaseAdminKey;
  
  // ===== ADMIN =====
  static String get adminEmail => EnvironmentConfig.adminEmail;
  static String get adminPassword => EnvironmentConfig.adminPassword;
  static String get adminPRN => EnvironmentConfig.adminPRN;
  
  // ===== APP =====
  static String get appName => EnvironmentConfig.appName;
  static String get appVersion => EnvironmentConfig.appVersion;
  static bool get isProduction => EnvironmentConfig.isProduction;
  
  // ===== VALIDATION =====
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseUrl.contains('YOUR_');
  }

  static void validateConfig() {
    if (!isConfigured) {
      throw Exception(
        'Supabase credentials not configured. '
        'Please copy env.example.dart to env.dart and fill in your credentials.'
      );
    }
  }
}
