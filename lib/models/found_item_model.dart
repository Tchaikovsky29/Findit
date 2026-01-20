/// Represents a found item reported in the Find-It application.
///
/// This model encapsulates all data related to items that have been found and reported
/// by users, including descriptions, locations, images, and AI-generated metadata.
/// It supports type-safe data handling and conversion for Supabase integration.
///
/// Example usage:
/// ```dart
/// FoundItemModel item = FoundItemModel(
///   id: 'uuid-123',
///   title: 'Lost Wallet',
///   description: 'Black leather wallet found near library',
///   location: 'Library Entrance',
///   userTags: ['wallet', 'leather', 'black'],
///   createdAt: DateTime.now(),
///   addedBy: 'user123',
///   updatedAt: DateTime.now(),
/// );
/// ```
class FoundItemModel {
  /// Unique identifier for the found item (UUID).
  final String id;

  /// Title or name of the found item.
  final String title;

  /// Detailed description of the found item.
  final String description;

  /// Location where the item was found.
  final String location;

  /// User-defined tags for categorization and search.
  final List<String> userTags;

  /// AI-detected primary object in the item's image (if available).
  final String? aiObject;

  /// AI-detected adjectives describing the item (if available).
  final List<String>? aiAdjectives;

  /// AI-generated description of the item (if available).
  final String? aiDescription;

  /// URL of the uploaded image of the found item (if available).
  final String? imageUrl;

  /// Timestamp when the item was reported.
  final DateTime createdAt;

  /// PRN of the user who reported the item.
  final String addedBy;

  /// Timestamp when the item was last updated.
  final DateTime updatedAt;

  /// Nested user details of the reporter (populated in some queries).
  final Map<String, dynamic>? userDetails;

  /// Creates a [FoundItemModel] instance.
  ///
  /// Most parameters are required except for AI-generated fields and image URL,
  /// which are optional and populated by external services.
  FoundItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.userTags,
    this.aiObject,
    this.aiAdjectives,
    this.aiDescription,
    this.imageUrl,
    required this.createdAt,
    required this.addedBy,
    required this.updatedAt,
    this.userDetails,
  });

  /// Creates a [FoundItemModel] from a JSON map received from Supabase.
  ///
  /// Handles complex data types like lists and nested objects safely.
  /// Provides sensible defaults for optional fields.
  ///
  /// Parameters:
  /// - [json]: A map containing found item data from the database.
  ///
  /// Returns:
  /// A [FoundItemModel] instance populated with the provided data.
  factory FoundItemModel.fromJson(Map<String, dynamic> json) {
    return FoundItemModel(
      id: json['id'] as String,  // Unique item identifier
      title: json['title'] as String,  // Item title
      description: json['description'] as String? ?? '',  // Item description, defaults to empty
      location: json['location'] as String,  // Found location
      userTags: List<String>.from(  // Convert tags array to List<String>
        (json['user_tags'] as List?) ?? []
      ),
      aiObject: json['ai_object'] as String?,  // AI-detected object
      aiAdjectives: json['ai_adjectives'] != null  // Convert adjectives if present
          ? List<String>.from(json['ai_adjectives'] as List)
          : null,
      aiDescription: json['ai_description'] as String?,  // AI-generated description
      imageUrl: json['image_url'] as String?,  // Image URL
      createdAt: DateTime.parse(json['created_at'] as String),  // Creation timestamp
      addedBy: json['added_by'] as String,  // Reporter's PRN
      updatedAt: DateTime.parse(json['updated_at'] as String),  // Last update timestamp
      userDetails: json['users'] as Map<String, dynamic>?,  // Nested user data
    );
  }

  /// Converts this [FoundItemModel] to a JSON map for API requests.
  ///
  /// Excludes read-only fields like id, timestamps, and userDetails
  /// since they are managed by the database.
  ///
  /// Returns:
  /// A [Map<String, dynamic>] representation suitable for database insertion/update.
  Map<String, dynamic> toJson() => {
    'title': title,  // Item title
    'description': description,  // Detailed description
    'location': location,  // Found location
    'user_tags': userTags,  // User-defined tags
    'ai_object': aiObject,  // AI-detected object
    'ai_adjectives': aiAdjectives,  // AI-detected adjectives
    'ai_description': aiDescription,  // AI-generated description
    'image_url': imageUrl,  // Image URL
    'added_by': addedBy,  // Reporter's PRN
  };
}