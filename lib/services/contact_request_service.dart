import '../models/contact_request_model.dart';
import '../models/supabase_service.dart';

/// Service class for managing contact request operations.
///
/// This service handles all operations related to the secure contact request
/// system, including creating requests, updating their status, and retrieving
/// requests for both requesters and item owners. It ensures privacy by
/// controlling when contact information is shared.
///
/// Example usage:
/// ```dart
/// final service = ContactRequestService();
/// final result = await service.createContactRequest(
///   itemId: 'item-uuid',
///   requesterPrn: 'my-prn',
///   message: 'I think this is mine',
/// );
/// ```
class ContactRequestService {
  final _supabaseService = SupabaseService();

  /// Create a new contact request
  Future<Map<String, dynamic>> createContactRequest({
    required String itemId,
    required String requesterPrn,
    String? message,
  }) async {
    try {
      final response = await _supabaseService.client.from('contact_requests').insert({
        'item_id': itemId,
        'requester_prn': requesterPrn,
        'message': message,
      }).select().single();

      return {
        'success': true,
        'request': ContactRequestModel.fromJson(response),
      };
    } catch (e) {
      print('Contact request error: $e');
      String errorMsg = 'Failed to create contact request';
      if (e.toString().contains('relation "contact_requests" does not exist')) {
        errorMsg = 'Database table not found. Please run the SQL script in database_schema.sql in your Supabase SQL editor.';
      } else if (e.toString().contains('permission denied')) {
        errorMsg = 'Permission denied. Please check your Supabase RLS policies.';
      }
      return {
        'success': false,
        'message': errorMsg,
      };
    }
  }

  /// Get contact requests for a specific item (for the owner)
  Future<List<ContactRequestModel>> getRequestsForItem(String itemId) async {
    try {
      final response = await _supabaseService.client
          .from('contact_requests')
          .select()
          .eq('item_id', itemId)
          .order('created_at', ascending: false);

      return response.map((json) => ContactRequestModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching contact requests: $e');
      return [];
    }
  }

  /// Get contact requests for items owned by a user (for item owners to see who wants to contact them)
  Future<List<ContactRequestModel>> getRequestsForUserItems(String ownerPrn) async {
    try {
      // Use a more direct approach with a manual join query
      final response = await _supabaseService.client
          .from('contact_requests')
          .select('*, found_items!inner(added_by)')
          .eq('found_items.added_by', ownerPrn)
          .order('created_at', ascending: false);

      // Map to ContactRequestModel objects
      final List<ContactRequestModel> requests = response
          .map((json) => ContactRequestModel.fromJson(json))
          .toList();

      return requests;
    } catch (e) {
      print('Error fetching user item contact requests: $e');
      // Try fallback approach if join fails
      try {
        // Fallback: Get all user's items first, then get requests
        final userItemsResponse = await _supabaseService.client
            .from('found_items')
            .select('id')
            .eq('added_by', ownerPrn);

        if (userItemsResponse.isEmpty) {
          return [];
        }

        // Get all contact requests
        final allRequestsResponse = await _supabaseService.client
            .from('contact_requests')
            .select()
            .order('created_at', ascending: false);

        // Extract item IDs safely
        final Set<String> userItemIds = {};
        for (var item in userItemsResponse) {
          if (item is Map && item.containsKey('id')) {
            userItemIds.add(item['id'].toString());
          }
        }

        // Filter requests manually
        final List<Map<String, dynamic>> userRequests = [];
        for (var request in allRequestsResponse) {
          if (request is Map<String, dynamic> && request.containsKey('item_id')) {
            if (userItemIds.contains(request['item_id'].toString())) {
              userRequests.add(request);
            }
          }
        }

        // Map to ContactRequestModel objects
        final List<ContactRequestModel> requests = userRequests
            .map((json) => ContactRequestModel.fromJson(json))
            .toList();

        return requests;
      } catch (fallbackError) {
        print('Fallback also failed: $fallbackError');
        return [];
      }
    }
  }

  /// Get contact requests made by a user
  Future<List<ContactRequestModel>> getRequestsByUser(String requesterPrn) async {
    try {
      final response = await _supabaseService.client
          .from('contact_requests')
          .select()
          .eq('requester_prn', requesterPrn)
          .order('created_at', ascending: false);

      return response.map((json) => ContactRequestModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching user contact requests: $e');
      return [];
    }
  }

  /// Update contact request status (approve/deny)
  Future<Map<String, dynamic>> updateRequestStatus(String requestId, String status) async {
    try {
      final response = await _supabaseService.client
          .from('contact_requests')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .select()
          .single();

      return {
        'success': true,
        'request': ContactRequestModel.fromJson(response),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update request status: $e',
      };
    }
  }

  /// Get a specific contact request
  Future<ContactRequestModel?> getContactRequest(String requestId) async {
    try {
      final response = await _supabaseService.client
          .from('contact_requests')
          .select()
          .eq('id', requestId)
          .single();

      return ContactRequestModel.fromJson(response);
    } catch (e) {
      print('Error fetching contact request: $e');
      return null;
    }
  }

  /// Check if user already has a pending request for this item
  Future<bool> hasPendingRequest(String itemId, String requesterPrn) async {
    try {
      final response = await _supabaseService.client
          .from('contact_requests')
          .select()
          .eq('item_id', itemId)
          .eq('requester_prn', requesterPrn)
          .eq('status', 'pending')
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking pending request: $e');
      return false;
    }
  }
}