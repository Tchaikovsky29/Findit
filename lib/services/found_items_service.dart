import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase_service.dart';
import '../models/found_item_model.dart';

/// Found Items Service - Handles CRUD operations for found items
/// Includes image upload to cloud storage

class FoundItemsService {
  final _supabaseService = SupabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Storage bucket name in Supabase
  static const String _storageBucket = 'found-items-images';
  
  // ===== READ OPERATIONS =====
  
  /// Fetch all found items with user details
  /// Includes join with users table to get reporter info
  /// Sorted by newest first
  /// 
  /// Returns: List of FoundItemModel objects
  Future<List<FoundItemModel>> getAllFoundItems() async {
    try {
      final response = await _supabaseService.client
          .from('found_items')
          .select('*, users(full_name, phone_number, email)')
          .order('created_at', ascending: false);
      
      // Convert JSON response to FoundItemModel list
      return (response as List)
          .map((json) => FoundItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('âŒ Error fetching items: $e');
      return [];
    }
  }
  
  /// Get found items added by specific user
  /// Filtered by added_by PRN
  /// 
  /// Params:
  ///   - prn: User's PRN
  /// 
  /// Returns: List of user's found items
  Future<List<FoundItemModel>> getUserFoundItems(String prn) async {
    try {
      final response = await _supabaseService.client
          .from('found_items')
          .select()
          .eq('added_by', prn)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => FoundItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('âŒ Error fetching user items: $e');
      return [];
    }
  }
  
  /// Get single found item by ID
  /// Includes user details
  /// 
  /// Returns: FoundItemModel or null if not found
  Future<FoundItemModel?> getFoundItemById(String itemId) async {
    try {
      final response = await _supabaseService.client
          .from('found_items')
          .select('*, users(full_name, phone_number, email)')
          .eq('id', itemId)
          .maybeSingle();
      
      if (response != null) {
        return FoundItemModel.fromJson(response as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('âŒ Error fetching item: $e');
      return null;
    }
  }
  
  /// Search found items by query
  /// Searches across title, description, and location
  /// Uses PostgreSQL ILIKE for case-insensitive matching
  /// 
  /// Params:
  ///   - query: Search string
  /// 
  /// Returns: Matching items
  Future<List<FoundItemModel>> searchFoundItems(String query) async {
    try {
      final response = await _supabaseService.client
          .from('found_items')
          .select('*, users(full_name, phone_number, email)')
          .or('title.ilike.%$query%,description.ilike.%$query%,location.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => FoundItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('âŒ Error searching items: $e');
      return [];
    }
  }
  
  /// Search items by tag
  /// Uses PostgreSQL array containment operator
  /// 
  /// Params:
  ///   - tag: Tag to search for
  /// 
  /// Returns: Items with matching tag
  Future<List<FoundItemModel>> searchByTag(String tag) async {
    try {
      final response = await _supabaseService.client
          .from('found_items')
          .select('*, users(full_name, phone_number, email)')
          .contains('user_tags', [tag])
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => FoundItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('âŒ Error searching by tag: $e');
      return [];
    }
  }
  
  // ===== IMAGE UPLOAD =====
  
  /// Upload image to Supabase Storage
  /// Files stored in public bucket with timestamp filename
  /// 
  /// Params:
  ///   - imageFile: File object from image picker
  /// 
  /// Returns: Public URL of uploaded image, or null on error
  /// 
  /// How it works:
  /// 1. Generate unique filename with timestamp
  /// 2. Upload file to storage bucket
  /// 3. Get public URL from storage
  /// 4. Return URL for saving in database
  Future<String?> uploadImage(File imageFile) async {
    try {
      // Generate unique filename to avoid conflicts
      // Format: {timestamp}.jpg (e.g., 1673456789012.jpg)
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('ðŸ“¤ Uploading image: $fileName');

      // Read file as bytes to handle different file path formats
      final bytes = await imageFile.readAsBytes();

      // Upload bytes to storage bucket with proper content type
      await _supabaseService.client.storage
          .from(_storageBucket)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: 'image/jpeg'),
          );

      // Get public URL for the uploaded file
      final publicUrl = _supabaseService.client.storage
          .from(_storageBucket)
          .getPublicUrl(fileName);

      print('âœ… Image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('âŒ Error uploading image: $e');
      return null;
    }
  }
  
  /// Pick image from device gallery
  /// 
  /// Returns: File object of selected image, or null if cancelled
  Future<File?> pickImageFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress to 80% quality
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('âŒ Error picking image: $e');
      return null;
    }
  }
  
  /// Pick image from camera
  /// 
  /// Returns: File object of captured image, or null if cancelled
  Future<File?> pickImageFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('âŒ Error capturing image: $e');
      return null;
    }
  }
  
  // ===== CREATE OPERATIONS =====
  
  /// Add new found item to database
  /// Handles image upload if provided
  /// 
  /// Params:
  ///   - title: Item title (required)
  ///   - description: Item description
  ///   - location: Location found (required)
  ///   - userTags: User-added tags for search
  ///   - aiObject: AI-detected main object
  ///   - aiAdjectives: AI-detected adjectives
  ///   - aiDescription: AI-generated description
  ///   - imageFile: Optional image file to upload
  /// 
  /// Returns: Result map with success status and inserted item data
  /// 
  /// Process:
  /// 1. Upload image if provided
  /// 2. Get public image URL
  /// 3. Insert item record with image URL
  /// 4. Return inserted data
  Future<Map<String, dynamic>> addFoundItem({
    required String title,
    required String description,
    required String location,
    required List<String> userTags,
    String? aiObject,
    List<String>? aiAdjectives,
    String? aiDescription,
    File? imageFile,
  }) async {
    try {
      // Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await uploadImage(imageFile);
        if (imageUrl == null) {
          return {
            'success': false,
            'message': 'Failed to upload image',
          };
        }
      }
      
      // Get current user PRN
      final userPRN = _supabaseService.currentUserPRN;
      if (userPRN == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Insert into database
      final response = await _supabaseService.client
          .from('found_items')
          .insert({
            'title': title,
            'description': description,
            'location': location,
            'user_tags': userTags,
            'ai_object': aiObject,
            'ai_adjectives': aiAdjectives,
            'ai_description': aiDescription,
            'image_url': imageUrl,
            'added_by': userPRN,
          })
          .select();
      
      return {
        'success': true,
        'message': 'Item added successfully',
        'data': response.isNotEmpty
            ? FoundItemModel.fromJson(response.first as Map<String, dynamic>)
            : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error adding item: ${e.toString()}',
      };
    }
  }
  
  // ===== UPDATE OPERATIONS =====
  
  /// Update found item details
  /// Only allows updating own items (enforced by RLS policy)
  /// 
  /// Params:
  ///   - itemId: Item to update (UUID)
  ///   - title: New title (optional)
  ///   - description: New description (optional)
  ///   - location: New location (optional)
  ///   - userTags: New tags (optional)
  /// 
  /// Returns: Success status
  Future<Map<String, dynamic>> updateFoundItem({
    required String itemId,
    String? title,
    String? description,
    String? location,
    List<String>? userTags,
  }) async {
    try {
      // Build update map with only provided fields
      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (location != null) updateData['location'] = location;
      if (userTags != null) updateData['user_tags'] = userTags;
      
      if (updateData.isEmpty) {
        return {
          'success': false,
          'message': 'No fields to update',
        };
      }
      
      // Update in database
      await _supabaseService.client
          .from('found_items')
          .update(updateData)
          .eq('id', itemId);
      
      return {
        'success': true,
        'message': 'Item updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating item: ${e.toString()}',
      };
    }
  }
  
  // ===== DELETE OPERATIONS =====
  
  /// Delete found item
  /// Only allows deleting own items (enforced by RLS policy)
  /// Also deletes associated image from storage
  /// 
  /// Params:
  ///   - itemId: Item to delete (UUID)
  ///   - imageUrl: URL of image to delete (optional)
  /// 
  /// Returns: Success status
  Future<Map<String, dynamic>> deleteFoundItem(
    String itemId, {
    String? imageUrl,
  }) async {
    try {
      // Delete image from storage if URL provided
      if (imageUrl != null) {
        try {
          // Extract filename from URL
          // URL format: https://.../{bucket}/{filename}
          final filename = imageUrl.split('/').last;
          
          await _supabaseService.client.storage
              .from(_storageBucket)
              .remove([filename]);
          
          print('âœ… Image deleted from storage');
        } catch (e) {
          print('âš ï¸ Warning: Could not delete image from storage: $e');
          // Continue with item deletion even if image delete fails
        }
      }
      
      // Delete item from database
      await _supabaseService.client
          .from('found_items')
          .delete()
          .eq('id', itemId);
      
      return {
        'success': true,
        'message': 'Item deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error deleting item: ${e.toString()}',
      };
    }
  }
  
  // ===== FILTER OPERATIONS =====
  
  /// Get found items from specific location
  /// 
  /// Params:
  ///   - location: Location to filter by
  /// 
  /// Returns: Items from that location
  Future<List<FoundItemModel>> getItemsByLocation(String location) async {
    try {
      final response = await _supabaseService.client
          .from('found_items')
          .select('*, users(full_name, phone_number, email)')
          .ilike('location', '%$location%')
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => FoundItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('âŒ Error fetching items by location: $e');
      return [];
    }
  }
  
  /// Get recent found items (last N days)
  /// 
  /// Params:
  ///   - days: Number of days to look back
  /// 
  /// Returns: Recent items
  Future<List<FoundItemModel>> getRecentItems({int days = 7}) async {
    try {
      final sinceDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();
      
      final response = await _supabaseService.client
          .from('found_items')
          .select('*, users(full_name, phone_number, email)')
          .gte('created_at', sinceDate)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => FoundItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('âŒ Error fetching recent items: $e');
      return [];
    }
  }
}