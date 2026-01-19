/// Found Item data model - represents an item reported as found
/// Used for type-safe handling of found items data
library;

class FoundItemModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final List<String> userTags;
  final String? aiObject;
  final List<String>? aiAdjectives;
  final String? aiDescription;
  final String? imageUrl;
  final DateTime createdAt;
  final String addedBy;
  final DateTime updatedAt;
  final Map<String, dynamic>? userDetails; // Nested user data
  
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
  
  /// Create FoundItemModel from Supabase response
  /// Handles arrays and nested relationships
  factory FoundItemModel.fromJson(Map<String, dynamic> json) {
    return FoundItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      location: json['location'] as String,
      userTags: List<String>.from(
        (json['user_tags'] as List?) ?? []
      ),
      aiObject: json['ai_object'] as String?,
      aiAdjectives: json['ai_adjectives'] != null
          ? List<String>.from(json['ai_adjectives'] as List)
          : null,
      aiDescription: json['ai_description'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      addedBy: json['added_by'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userDetails: json['users'] as Map<String, dynamic>?,
    );
  }
  
  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'location': location,
    'user_tags': userTags,
    'ai_object': aiObject,
    'ai_adjectives': aiAdjectives,
    'ai_description': aiDescription,
    'image_url': imageUrl,
    'added_by': addedBy,
  };
}