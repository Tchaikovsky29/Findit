import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'config.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ===== ADMIN OPERATIONS =====
  
  /// Create admin user in users table
  static Future<bool> initializeAdmin() async {
    try {
      // Check if admin already exists
      final existing = await _client
          .from('users')
          .select()
          .eq('prn', AppConfig.adminPRN);

      if (existing.isNotEmpty) {
        return true;
      }

      // Hash admin password
      final adminPasswordHash = _hashPassword(AppConfig.adminPassword);

      // Create admin user
      await _client.from('users').insert({
        'prn': AppConfig.adminPRN,
        'password_hash': adminPasswordHash,
        'full_name': 'Administrator',
        'year': 4,
        'branch': 'Administration',
        'department': 'Management',
        'phone_number': '9999999999',
        'email': AppConfig.adminEmail,
        'theme_preference': 'light',
        'is_admin': true,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is admin
  static Future<bool> isUserAdmin(String prn) async {
    try {
      final response = await _client
          .from('users')
          .select('is_admin')
          .eq('prn', prn)
          .single();
      
      return response['is_admin'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // ===== AUTHENTICATION =====
  
  static Future<bool> registerUser({
    required String prn,
    required String password,
    required String fullName,
    required int year,
    required String branch,
    required String department,
    required String phone,
    required String email,
  }) async {
    try {
      final passwordHash = _hashPassword(password);

      await _client.from('users').insert({
        'prn': prn,
        'password_hash': passwordHash,
        'full_name': fullName,
        'year': year,
        'branch': branch,
        'department': department,
        'phone_number': phone,
        'email': email,
        'theme_preference': 'light',
        'is_admin': false,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> loginUser(
    String prn,
    String password,
  ) async {
    try {
      final passwordHash = _hashPassword(password);

      final response = await _client
          .from('users')
          .select()
          .eq('prn', prn)
          .single();

      if (response['password_hash'] == passwordHash) {
        return response;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ===== HELPER =====
  
  static String _hashPassword(String password) {
    return sha256.convert(password.codeUnits).toString();
  }
}