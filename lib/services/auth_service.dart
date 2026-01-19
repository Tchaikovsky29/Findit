import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase_service.dart';
import '../models/user_model.dart';

/// Authentication Service - Handles signup, login, and user management
/// All password hashing happens on client side for security

class AuthService {
  final _supabaseService = SupabaseService();
  
  /// Hash password using SHA-256 algorithm
  /// This is what gets stored in database (not plaintext)
  /// Uses SHA-256 for one-way hashing
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
  
  // ===== SIGNUP FUNCTIONALITY =====
  
  /// Register new user account
  /// Params:
  ///   - prn: Student's PRN (e.g., CS12345)
  ///   - password: User's password (hashed before storage)
  ///   - fullName: Student's full name
  ///   - year: Academic year (1-4)
  ///   - branch: Course branch (CSE, IT, etc.)
  ///   - department: Department (B.Tech, M.Tech)
  ///   - phoneNumber: Contact number
  ///   - email: Email address
  /// 
  /// Returns: Map with 'success' bool and 'message' string
  Future<Map<String, dynamic>> signup({
    required String prn,
    required String password,
    required String fullName,
    required int year,
    required String branch,
    required String department,
    required String phoneNumber,
    required String email,
  }) async {
    try {
      // Hash password before sending to server
      final passwordHash = _hashPassword(password);

      // Insert new user into database
      final response = await _supabaseService.client
          .from('users')
          .insert({
            'prn': prn,
            'password_hash': passwordHash,
            'full_name': fullName,
            'year': year,
            'branch': branch,
            'department': department,
            'phone_number': phoneNumber,
            'email': email,
            'theme_preference': 'light',
            'is_admin': false,
          })
          .select(); // Return inserted data
      
      if (response.isNotEmpty) {
        // Automatically log in user after signup
        await _supabaseService.saveUserPRN(prn);
        return {
          'success': true,
          'message': 'Signup successful! You are now logged in.',
          'user': UserModel.fromJson(response.first),
        };
      }
      
      return {
        'success': false,
        'message': 'Signup failed. Please try again.',
      };
    } on PostgrestException catch (e) {
      // Handle database-specific errors
      if (e.code == '23505') {
        // Unique constraint violation (duplicate email or PRN)
        return {
          'success': false,
          'message': 'Email or PRN already exists. Please use different credentials.',
        };
      }
      return {
        'success': false,
        'message': 'Database error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error during signup: ${e.toString()}',
      };
    }
  }
  
  // ===== LOGIN FUNCTIONALITY =====
  
  /// Authenticate user and create session
  /// Params:
  ///   - prn: Student's PRN
  ///   - password: Password (hashed before comparison)
  /// 
  /// Returns: Map with success status and user data
  /// 
  /// How it works:
  /// 1. Hash the provided password
  /// 2. Query database for user with matching PRN and password_hash
  /// 3. If found, save PRN locally and return user data
  /// 4. If not found, return error (invalid credentials)
  Future<Map<String, dynamic>> login({
    required String prn,
    required String password,
  }) async {
    try {
      // Hash password to match against database
      final passwordHash = _hashPassword(password);
      
      // Query: Find user with matching PRN and password_hash
      final response = await _supabaseService.client
          .from('users')
          .select()
          .eq('prn', prn)
          .eq('password_hash', passwordHash)
          .maybeSingle(); // Returns single row or null
      
      if (response != null) {
        // User found - authentication successful
        final user = UserModel.fromJson(response);
        
        // Save PRN locally for future sessions
        await _supabaseService.saveUserPRN(prn);
        
        return {
          'success': true,
          'message': 'Login successful!',
          'user': user,
        };
      }
      
      // User not found - invalid credentials
      return {
        'success': false,
        'message': 'Invalid PRN or password. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error during login: ${e.toString()}',
      };
    }
  }
  
  // ===== LOGOUT FUNCTIONALITY =====
  
  /// Clear user session
  /// Removes stored PRN from local storage
  /// User will need to login again on next app open
  Future<void> logout() async {
    try {
      await _supabaseService.clearUserPRN();
      print('âœ… User logged out successfully');
    } catch (e) {
      print('âŒ Error during logout: $e');
    }
  }
  
  // ===== USER RETRIEVAL =====
  
  /// Get user details by PRN
  /// Used to fetch user profile information
  /// Returns null if user not found
  Future<UserModel?> getUserDetails(String prn) async {
    try {
      final response = await _supabaseService.client
          .from('users')
          .select()
          .eq('prn', prn)
          .maybeSingle();
      
      if (response != null) {
        return UserModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('âŒ Error fetching user: $e');
      return null;
    }
  }
  
  /// Get current logged-in user details
  /// Combines local storage PRN with database lookup
  Future<UserModel?> getCurrentUser() async {
    final currentPRN = _supabaseService.currentUserPRN;
    if (currentPRN == null) return null;
    
    return await getUserDetails(currentPRN);
  }
  
  // ===== PROFILE UPDATES =====
  
  /// Update user profile information
  /// Params:
  ///   - prn: User's PRN (required - used to identify user)
  ///   - fullName: New full name (optional)
  ///   - phoneNumber: New phone number (optional)
  ///   - email: New email (optional) - must be unique
  ///   - year: New year (optional)
  ///   - branch: New branch (optional)
  ///   - department: New department (optional)
  ///   - themePreference: light or dark (optional)
  ///
  /// Returns: Success status
  Future<Map<String, dynamic>> updateProfile({
    required String prn,
    String? fullName,
    String? phoneNumber,
    String? email,
    int? year,
    String? branch,
    String? department,
    String? themePreference,
  }) async {
    try {
      // Build update map with only provided fields
      final updateData = <String, dynamic>{};

      if (fullName != null) updateData['full_name'] = fullName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (email != null) updateData['email'] = email;
      if (year != null) updateData['year'] = year;
      if (branch != null) updateData['branch'] = branch;
      if (department != null) updateData['department'] = department;
      if (themePreference != null) {
        updateData['theme_preference'] = themePreference;
        // Also save to local preferences
        await _supabaseService.saveThemePreference(themePreference);
      }

      // Update database record
      await _supabaseService.client
          .from('users')
          .update(updateData)
          .eq('prn', prn);

      return {
        'success': true,
        'message': 'Profile updated successfully',
      };
    } on PostgrestException catch (e) {
      // Handle database-specific errors
      if (e.code == '23505') {
        // Unique constraint violation (duplicate email)
        return {
          'success': false,
          'message': 'Email already exists. Please use a different email.',
        };
      }
      return {
        'success': false,
        'message': 'Database error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating profile: ${e.toString()}',
      };
    }
  }
  
  // ===== PASSWORD CHANGE =====
  
  /// Change user password
  /// Params:
  ///   - prn: User's PRN
  ///   - oldPassword: Current password (verified)
  ///   - newPassword: New password to set
  /// 
  /// Returns: Success status
  Future<Map<String, dynamic>> changePassword({
    required String prn,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // Verify old password is correct
      final loginResult = await login(prn: prn, password: oldPassword);
      if (!loginResult['success']) {
        return {
          'success': false,
          'message': 'Current password is incorrect',
        };
      }
      
      // Hash new password and update
      final newPasswordHash = _hashPassword(newPassword);
      
      await _supabaseService.client
          .from('users')
          .update({'password_hash': newPasswordHash})
          .eq('prn', prn);
      
      return {
        'success': true,
        'message': 'Password changed successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error changing password: ${e.toString()}',
      };
    }
  }
}