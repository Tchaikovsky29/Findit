/// SECURITY: This is an EXAMPLE file
/// DO NOT commit actual credentials
/// Copy to env.dart and fill with real values
/// env.dart is in .gitignore (not committed)
library;

class EnvironmentConfig {
  // ===== SUPABASE CREDENTIALS =====
  static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
  
  // ===== ADMIN CREDENTIALS =====
  static const String adminEmail = 'admin@findit.local';
  static const String adminPassword = 'CHANGE_ME_IN_PRODUCTION';
  static const String adminPRN = 'ADMIN001';
  
  // ===== SUPABASE ADMIN API KEY =====
  // Use only in backend/admin operations (NOT in Flutter app)
  static const String supabaseAdminKey = 'YOUR_SUPABASE_SERVICE_ROLE_KEY_HERE';
  
  // ===== APP CONFIGURATION =====
  static const String appName = 'Find-It';
  static const String appVersion = '4.1';
  static const bool isProduction = false;
  
  // ===== API ENDPOINTS =====
  static const String apiBaseUrl = 'https://your-domain.com/api';
  static const int apiTimeout = 30; // seconds
}