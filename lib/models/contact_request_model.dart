/// Represents a contact request between a finder and an item reporter.
///
/// This model manages the secure contact request system in the Find-It application.
/// Requests go through an approval workflow to protect user privacy, allowing
/// item reporters to control who can access their contact information.
///
/// Example usage:
/// ```dart
/// ContactRequestModel request = ContactRequestModel(
///   id: 'uuid-456',
///   itemId: 'item-uuid',
///   requesterPrn: '123456',
///   status: 'pending',
///   message: 'I think this is my wallet',
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
/// ```
class ContactRequestModel {
  /// Unique identifier for the contact request (UUID).
  final String id;

  /// ID of the found item this request is about.
  final String itemId;

  /// PRN of the user making the contact request.
  final String requesterPrn;

  /// Current status of the request ('pending', 'approved', 'denied').
  final String status;

  /// Optional message from the requester explaining their claim.
  final String? message;

  /// Timestamp when the request was created.
  final DateTime createdAt;

  /// Timestamp when the request was last updated.
  final DateTime updatedAt;

  /// Creates a [ContactRequestModel] instance.
  ///
  /// All fields except [message] are required. The [status] should be one of:
  /// 'pending', 'approved', or 'denied'.
  ContactRequestModel({
    required this.id,
    required this.itemId,
    required this.requesterPrn,
    required this.status,
    this.message,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [ContactRequestModel] from a JSON map received from Supabase.
  ///
  /// Handles type conversion safely, converting all values to strings first
  /// then parsing dates appropriately.
  ///
  /// Parameters:
  /// - [json]: A map containing contact request data from the database.
  ///
  /// Returns:
  /// A [ContactRequestModel] instance populated with the provided data.
  factory ContactRequestModel.fromJson(Map<String, dynamic> json) {
    return ContactRequestModel(
      id: json['id'].toString(),  // Request UUID
      itemId: json['item_id'].toString(),  // Referenced item ID
      requesterPrn: json['requester_prn'].toString(),  // Requester's PRN
      status: json['status'].toString(),  // Request status
      message: json['message']?.toString(),  // Optional request message
      createdAt: DateTime.parse(json['created_at'].toString()),  // Creation timestamp
      updatedAt: DateTime.parse(json['updated_at'].toString()),  // Update timestamp
    );
  }

  /// Converts this [ContactRequestModel] to a JSON map for API requests.
  ///
  /// Excludes read-only fields like id and timestamps since they are
  /// managed by the database.
  ///
  /// Returns:
  /// A [Map<String, dynamic>] suitable for database operations.
  Map<String, dynamic> toJson() => {
    'item_id': itemId,  // Referenced item
    'requester_prn': requesterPrn,  // Requester identifier
    'status': status,  // Current status
    'message': message,  // Optional message
  };
}