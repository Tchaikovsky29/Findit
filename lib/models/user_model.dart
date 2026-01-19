/// User data model - represents a user in the system
/// Used for type-safe data handling throughout the app
library;

class UserModel {
  final String prn;
  final String fullName;
  final int year;
  final String branch;
  final String department;
  final String phoneNumber;
  final String email;
  final String themePreference;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.prn,
    required this.fullName,
    required this.year,
    required this.branch,
    required this.department,
    required this.phoneNumber,
    required this.email,
    this.themePreference = 'light',
    this.isAdmin = false,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Create UserModel from Supabase response
  /// Handles JSON to Dart conversion
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      prn: json['prn'] as String,
      fullName: json['full_name'] as String,
      year: json['year'] as int,
      branch: json['branch'] as String,
      department: json['department'] as String,
      phoneNumber: json['phone_number'] as String? ?? '',
      email: json['email'] as String,
      themePreference: json['theme_preference'] as String? ?? 'light',
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  /// Convert UserModel to JSON for sending to Supabase
  Map<String, dynamic> toJson() => {
    'prn': prn,
    'full_name': fullName,
    'year': year,
    'branch': branch,
    'department': department,
    'phone_number': phoneNumber,
    'email': email,
    'theme_preference': themePreference,
    'is_admin': isAdmin,
  };
}