import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

/// Service class for managing Supabase client initialization and local storage.
///
/// This singleton service handles all interactions with the Supabase backend,
/// including client initialization, authentication state management, and
/// local data persistence. It provides a centralized way to access the
/// Supabase client and manage user session data.
///
/// Example usage:
/// ```dart
/// await SupabaseService().initialize();
/// final client = SupabaseService().client;
/// ```
class SupabaseService {
  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();
  
  late final SupabaseClient _client;
  late final SharedPreferences _prefs;
  
  // Constructor for singleton pattern
  factory SupabaseService() => _instance;
  
  SupabaseService._internal();
  
  /// Initializes the Supabase client and local storage.
  ///
  /// This method must be called in `main()` before the app runs.
  /// It sets up the Supabase client with the provided configuration and
  /// initializes shared preferences for local data storage.
  ///
  /// Requires an active internet connection for Supabase initialization.
  /// Throws an exception if initialization fails.
  ///
  /// Returns:
  /// A [Future] that completes when initialization is successful.
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