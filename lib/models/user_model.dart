/// Represents a user in the Find-It application.
///
/// This model encapsulates all user-related data including personal information,
/// academic details, and application preferences. It provides type-safe data
/// handling and conversion methods for Supabase integration.
///
/// Example usage:
/// ```dart
/// UserModel user = UserModel(
///   prn: '123456',
///   fullName: 'John Doe',
///   year: 3,
///   branch: 'Computer Science',
///   department: 'Engineering',
///   phoneNumber: '+1234567890',
///   email: 'john.doe@university.edu',
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
/// ```
class UserModel {
  /// Unique Personal Registration Number (PRN) of the user.
  final String prn;

  /// Full name of the user.
  final String fullName;

  /// Academic year of the user (e.g., 1, 2, 3, 4).
  final int year;

  /// Academic branch or specialization (e.g., "Computer Science").
  final String branch;

  /// Academic department (e.g., "Engineering").
  final String department;

  /// Phone number of the user.
  final String phoneNumber;

  /// Email address of the user.
  final String email;

  /// User's theme preference ('light' or 'dark').
  final String themePreference;

  /// Whether the user has administrative privileges.
  final bool isAdmin;

  /// Timestamp when the user account was created.
  final DateTime createdAt;

  /// Timestamp when the user account was last updated.
  final DateTime updatedAt;

  /// Creates a [UserModel] instance.
  ///
  /// All required parameters must be provided except for [themePreference] and [isAdmin],
  /// which default to 'light' and false respectively.
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

  /// Creates a [UserModel] from a JSON map received from Supabase.
  ///
  /// Handles null values gracefully by providing defaults where appropriate.
  /// Throws a [FormatException] if required fields are missing or invalid.
  ///
  /// Parameters:
  /// - [json]: A map containing user data from the database.
  ///
  /// Returns:
  /// A [UserModel] instance populated with the provided data.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      prn: json['prn'] as String,  // Unique identifier
      fullName: json['full_name'] as String,  // User's complete name
      year: json['year'] as int,  // Academic year
      branch: json['branch'] as String,  // Academic branch
      department: json['department'] as String,  // Academic department
      phoneNumber: json['phone_number'] as String? ?? '',  // Contact number, defaults to empty string
      email: json['email'] as String,  // Email address
      themePreference: json['theme_preference'] as String? ?? 'light',  // UI theme preference
      isAdmin: json['is_admin'] as bool? ?? false,  // Administrative privileges
      createdAt: DateTime.parse(json['created_at'] as String),  // Account creation timestamp
      updatedAt: DateTime.parse(json['updated_at'] as String),  // Last update timestamp
    );
  }

  /// Converts this [UserModel] to a JSON map for Supabase operations.
  ///
  /// Only includes fields that are typically sent to the database.
  /// Timestamps are handled by the database and not included here.
  ///
  /// Returns:
  /// A [Map<String, dynamic>] representation of the user data.
  Map<String, dynamic> toJson() => {
    'prn': prn,  // Primary key
    'full_name': fullName,  // User's full name
    'year': year,  // Academic year
    'branch': branch,  // Academic branch
    'department': department,  // Academic department
    'phone_number': phoneNumber,  // Contact phone number
    'email': email,  // Email address
    'theme_preference': themePreference,  // UI theme choice
    'is_admin': isAdmin,  // Administrative status
  };
}