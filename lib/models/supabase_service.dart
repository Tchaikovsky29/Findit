import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

/// Supabase Service - Handles all Supabase initialization and connection
/// Implements Singleton pattern to ensure only one instance exists

class SupabaseService {
  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();
  
  late final SupabaseClient _client;
  late final SharedPreferences _prefs;
  
  // Constructor for singleton pattern
  factory SupabaseService() => _instance;
  
  SupabaseService._internal();
  
  /// Initialize Supabase client
  /// Call this in main() before running the app
  /// Requires internet connection
  Future<void> initialize() async {
    try {
      // Load shared preferences for local storage
      _prefs = await SharedPreferences.getInstance();
      
      // Initialize Supabase with credentials from config
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        debug: !AppConfig.isProduction,
      );
      
      // Get the Supabase client
      _client = Supabase.instance.client;
      
      print('âœ… Supabase initialized successfully');
    } catch (e) {
      print('âŒ Supabase initialization failed: $e');
      rethrow; // Re-throw to handle in main.dart
    }
  }
  
  // ===== GETTERS =====
  
  /// Get Supabase client for database operations
  SupabaseClient get client => _client;
  
  /// Get SharedPreferences instance
  SharedPreferences get prefs => _prefs;
  
  /// Get current logged-in user's PRN
  /// Returns null if not logged in
  String? get currentUserPRN => _prefs.getString('user_prn');
  
  /// Check if user is currently authenticated
  /// Used in route guards and UI conditionals
  bool get isAuthenticated => currentUserPRN != null;
  
  // ===== LOCAL STORAGE METHODS =====
  
  /// Save user PRN locally after successful login
  Future<void> saveUserPRN(String prn) async {
    await _prefs.setString('user_prn', prn);
  }
  
  /// Clear stored user PRN on logout
  Future<void> clearUserPRN() async {
    await _prefs.remove('user_prn');
  }
  
  /// Save user theme preference
  Future<void> saveThemePreference(String theme) async {
    await _prefs.setString('theme_preference', theme);
  }
  
  /// Get saved theme preference
  String getThemePreference() {
    return _prefs.getString('theme_preference') ?? 'light';
  }
}