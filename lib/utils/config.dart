import '../env.dart';

/// Configuration wrapper that provides easy access to environment variables
/// This layer of abstraction allows easy switching between environments

class AppConfig {
  // ===== SUPABASE CONFIGURATION =====
  static String get supabaseUrl => EnvironmentConfig.supabaseUrl;
  static String get supabaseAnonKey => EnvironmentConfig.supabaseAnonKey;
  static String get supabaseAdminKey => EnvironmentConfig.supabaseAdminKey;
  
  // ===== ADMIN CREDENTIALS =====
  static String get adminEmail => EnvironmentConfig.adminEmail;
  static String get adminPassword => EnvironmentConfig.adminPassword;
  static String get adminPRN => EnvironmentConfig.adminPRN;
  
  // ===== APP INFO =====
  static String get appName => EnvironmentConfig.appName;
  static String get appVersion => EnvironmentConfig.appVersion;
  static bool get isProduction => EnvironmentConfig.isProduction;
  
  /// Validates if Supabase credentials are properly configured
  /// Returns true if both URL and Anon Key are provided
  static bool get isConfigured => 
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}