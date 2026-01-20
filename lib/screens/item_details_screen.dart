import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/found_item_model.dart';
import '../utils/constants.dart';
import '../services/contact_request_service.dart';
import '../models/supabase_service.dart';
import '../models/contact_request_model.dart';

/// Item Details Screen
/// Shows full information about a found item with enhanced design
/// Implements approval-based contact system with real-time notifications
class ItemDetailsScreen extends StatefulWidget {
  final FoundItemModel item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final _contactRequestService = ContactRequestService();
  final _supabaseService = SupabaseService();
  bool _isLoading = false;
  ContactRequestModel? _existingRequest;
  bool _checkingRequest = true;
  Timer? _statusPollingTimer;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    super.dispose();
  }

  /// Check if user already has a pending request for this item
  Future<void> _checkExistingRequest() async {
    if (_supabaseService.currentUserPRN == null) {
      setState(() => _checkingRequest = false);
      return;
    }

    final hasPending = await _contactRequestService.hasPendingRequest(
      widget.item.id,
      _supabaseService.currentUserPRN!,
    );

    if (hasPending) {
      final requests = await _contactRequestService.getRequestsByUser(_supabaseService.currentUserPRN!);
      final request = requests.where((r) => r.itemId == widget.item.id).firstOrNull;
      setState(() {
        _existingRequest = request;
        _checkingRequest = false;
      });
      _startStatusPolling(); // Start polling after we have an existing request
    } else {
      setState(() => _checkingRequest = false);
    }
  }

  /// Start polling for request status updates
  void _startStatusPolling() {
    // Only poll if user has an existing request
    if (_existingRequest == null || _supabaseService.currentUserPRN == null) return;

    _statusPollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted || _supabaseService.currentUserPRN == null) return;

      try {
        final requests = await _contactRequestService.getRequestsByUser(_supabaseService.currentUserPRN!);
        final updatedRequest = requests.where((r) => r.itemId == widget.item.id).firstOrNull;

        if (updatedRequest != null && updatedRequest.status != _existingRequest!.status) {
          setState(() {
            _existingRequest = updatedRequest;
          });
          // Show notification if status changed to approved
          if (updatedRequest.status == 'approved' && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contact request approved! You can now contact the reporter.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        // Silently handle polling errors
        print('Status polling error: $e');
      }
    });
  }

  /// Send contact request to reporter
  Future<void> _sendContactRequest() async {
    if (_supabaseService.currentUserPRN == null) {
      _showSnackBar('Please login to send contact requests', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _contactRequestService.createContactRequest(
        itemId: widget.item.id,
        requesterPrn: _supabaseService.currentUserPRN!,
        message: 'I\'m interested in the ${widget.item.title} you found.',
      );

      if (result['success']) {
        _showSnackBar('Contact request sent! Waiting for approval.');
        await _checkExistingRequest(); // Refresh the request status (this will start polling)
      } else {
        _showSnackBar(result['message'] ?? 'Failed to send request', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error sending request', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Contact reporter via phone
  Future<void> _contactViaPhone() async {
    final reporterPhone = widget.item.userDetails?['phone_number'];
    if (reporterPhone == null) {
      _showSnackBar('Reporter phone number not available', isError: true);
      return;
    }

    final phoneUri = Uri(
      scheme: 'tel',
      path: reporterPhone,
    );

    try {
      await launchUrl(phoneUri);
    } catch (e) {
      _showSnackBar('Could not open phone app', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getRequestStatusText() {
    if (_existingRequest == null) return '';

    switch (_existingRequest!.status) {
      case 'pending':
        return 'Request sent - waiting for approval';
      case 'approved':
        return 'Request approved! You can now contact the reporter';
      case 'denied':
        return 'Request denied - you can try again later';
      default:
        return '';
    }
  }

  Color _getRequestStatusColor() {
    if (_existingRequest == null) return Colors.white;

    switch (_existingRequest!.status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'denied':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isOwnItem = item.addedBy == _supabaseService.currentUserPRN;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Enhanced Header with Gradient
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppConstants.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Item Image or Placeholder
                  if (item.imageUrl != null)
                    Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 80,
                            color: Colors.white54,
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: AppConstants.primaryColor.withOpacity(0.8),
                      child: const Icon(
                        Icons.inventory_2,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
                  // Gradient Overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          item.location,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description Section
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // User Description
                  if (item.description.isNotEmpty) ...[
                    const Text(
                      'User Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // AI Description
                  if (item.aiDescription != null && item.aiDescription!.isNotEmpty) ...[
                    const Text(
                      'AI Analysis',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.aiDescription!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // AI Characteristics (Adjectives as tags)
                  if (item.aiAdjectives != null && item.aiAdjectives!.isNotEmpty) ...[
                    const Text(
                      'AI Tags',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.aiAdjectives!.map((adjective) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 51, 51, 51).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20)
                          ),
                          child: Text(
                            adjective,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Tags
                  if (item.userTags.isNotEmpty) ...[
                    const Text(
                      'User Tags',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.userTags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppConstants.secondaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Reporter Info
                  const Text(
                    'Reported By',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.userDetails?['full_name'] ?? 'Unknown User',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'PRN: ${item.addedBy}',
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                              Text(
                                'Found on: ${item.createdAt.toString().split(' ')[0]}',
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Contact Section (only if not own item)
                  if (!isOwnItem) ...[
                    const Text(
                      'Contact Reporter',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Request Status
                    if (_existingRequest != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getRequestStatusColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getRequestStatusColor()),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _existingRequest!.status == 'pending'
                                  ? Icons.hourglass_empty
                                  : _existingRequest!.status == 'approved'
                                      ? Icons.check_circle
                                      : Icons.cancel,
                              color: _getRequestStatusColor(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getRequestStatusText(),
                                style: TextStyle(color: _getRequestStatusColor()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Contact Information (only if approved)
                    if (_existingRequest?.status == 'approved') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            if (item.userDetails?['email'] != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.email, color: Colors.white70, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.userDetails!['email'],
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                                    onPressed: () {
                                      _showSnackBar('Email copied to clipboard');
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (item.userDetails?['phone_number'] != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.phone, color: Colors.white70, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.userDetails!['phone_number'],
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.call, color: Colors.green, size: 20),
                                    onPressed: _contactViaPhone,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else if (_existingRequest?.status != 'denied' || _checkingRequest) ...[
                      // Send Request Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_isLoading || _checkingRequest) ? null : _sendContactRequest,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send),
                          label: Text(_checkingRequest ? 'Checking...' : 'Send Contact Request'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.secondaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Retry Button for denied requests
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _sendContactRequest,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Send New Request'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}