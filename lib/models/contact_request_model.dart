/// Contact Request data model
/// Represents a request to contact the owner of a found item
library;

class ContactRequestModel {
  final String id;
  final String itemId;
  final String requesterPrn;
  final String status; // 'pending', 'approved', 'denied'
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactRequestModel({
    required this.id,
    required this.itemId,
    required this.requesterPrn,
    required this.status,
    this.message,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ContactRequestModel from Supabase response
  factory ContactRequestModel.fromJson(Map<String, dynamic> json) {
    return ContactRequestModel(
      id: json['id'].toString(),
      itemId: json['item_id'].toString(),
      requesterPrn: json['requester_prn'].toString(),
      status: json['status'].toString(),
      message: json['message']?.toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'requester_prn': requesterPrn,
    'status': status,
    'message': message,
  };
}