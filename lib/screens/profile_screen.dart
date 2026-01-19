import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../models/supabase_service.dart';
import '../services/auth_service.dart';
import '../services/found_items_service.dart';
import '../models/found_item_model.dart';
import '../services/contact_request_service.dart';
import '../models/contact_request_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _contactRequestService = ContactRequestService();
  final _authService = AuthService();
  final _foundItemsService = FoundItemsService();
  final _supabaseService = SupabaseService();

  late TabController _tabController;
  Map<String, dynamic>? _userProfile;
  bool _isEditing = false;
  bool _loadingProfile = true;
  List<FoundItemModel> _myItems = [];
  bool _loadingMyItems = true;
  List<ContactRequestModel> _contactRequests = [];
  bool _loadingRequests = true;
  Timer? _notificationTimer;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _yearController;
  late TextEditingController _branchController;
  late TextEditingController _departmentController;

  // Password change controllers
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _yearController = TextEditingController();
    _branchController = TextEditingController();
    _departmentController = TextEditingController();

    _loadProfile();
    _loadMyItems();
    _loadContactRequests();
    _startNotificationPolling();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        setState(() {
          _userProfile = {
            'prn': user.prn,
            'full_name': user.fullName,
            'email': user.email,
            'phone_number': user.phoneNumber,
            'year': user.year,
            'branch': user.branch,
            'department': user.department,
            'theme_preference': user.themePreference,
          };
          _nameController.text = user.fullName;
          _emailController.text = user.email;
          _phoneController.text = user.phoneNumber;
          _yearController.text = user.year.toString();
          _branchController.text = user.branch;
          _departmentController.text = user.department;
          _loadingProfile = false;
        });
      } else {
        setState(() => _loadingProfile = false);
        // Handle user not found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile')),
        );
      }
    } catch (e) {
      setState(() => _loadingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _loadMyItems() async {
    if (_supabaseService.currentUserPRN == null) {
      setState(() => _loadingMyItems = false);
      return;
    }
    setState(() => _loadingMyItems = true);
    try {
      final items = await _foundItemsService.getUserFoundItems(_supabaseService.currentUserPRN!);
      setState(() {
        _myItems = items;
        _loadingMyItems = false;
      });
    } catch (e) {
      setState(() => _loadingMyItems = false);
      print('Error loading my items: $e');
    }
  }

  Future<void> _deleteItem(String itemId, String? imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: const Text('Delete Item', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this item?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final result = await _foundItemsService.deleteFoundItem(itemId, imageUrl: imageUrl);
        if (result['success']) {
          await _loadMyItems();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _yearController.dispose();
    _branchController.dispose();
    _departmentController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startNotificationPolling() {
    // Poll for new contact requests every 30 seconds
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted || _supabaseService.currentUserPRN == null) return;

      try {
        final currentRequests = await _contactRequestService.getRequestsForUserItems(_supabaseService.currentUserPRN!);
        final newPendingRequests = currentRequests.where((r) => r.status == 'pending').length;
        final oldPendingRequests = _contactRequests.where((r) => r.status == 'pending').length;

        // If there are new pending requests, show notification and refresh
        if (newPendingRequests > oldPendingRequests) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('New contact request received!'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () {
                    _tabController.animateTo(1); // Switch to contact requests tab
                  },
                ),
              ),
            );
          }
          await _loadContactRequests(); // Refresh the list
        } else if (currentRequests.length != _contactRequests.length) {
          // If request count changed (approvals/denials), refresh
          await _loadContactRequests();
        }
      } catch (e) {
        // Silently handle polling errors
        print('Notification polling error: $e');
      }
    });
  }

  Future<void> _loadContactRequests() async {
    if (_supabaseService.currentUserPRN == null) {
      setState(() => _loadingRequests = false);
      return;
    }

    setState(() => _loadingRequests = true);

    try {
      final requests = await _contactRequestService.getRequestsForUserItems(_supabaseService.currentUserPRN!);
      // Sort by creation date, newest first
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final pendingCount = requests.where((r) => r.status == 'pending').length;

      setState(() {
        _contactRequests = requests;
        _loadingRequests = false;
      });

      // Show notification if there are pending requests when first loading
      if (pendingCount > 0 && mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You have $pendingCount pending contact request${pendingCount > 1 ? 's' : ''}!'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () {
                    _tabController.animateTo(1); // Switch to contact requests tab
                  },
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      print('Error loading contact requests: $e');
      setState(() => _loadingRequests = false);
    }
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    try {
      final result = await _contactRequestService.updateRequestStatus(requestId, status);
      if (result['success']) {
        await _loadContactRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${status == 'approved' ? 'approved' : 'denied'}'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && _userProfile != null) {
      try {
        final result = await _authService.updateProfile(
          prn: _userProfile!['prn'],
          fullName: _nameController.text,
          email: _emailController.text,
          phoneNumber: _phoneController.text,
          year: int.tryParse(_yearController.text),
          branch: _branchController.text,
          department: _departmentController.text,
        );
        if (result['success']) {
          setState(() {
            _userProfile!['full_name'] = _nameController.text;
            _userProfile!['email'] = _emailController.text;
            _userProfile!['phone_number'] = _phoneController.text;
            _userProfile!['year'] = int.tryParse(_yearController.text) ?? _userProfile!['year'];
            _userProfile!['branch'] = _branchController.text;
            _userProfile!['department'] = _departmentController.text;
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppConstants.successColor,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final _passwordFormKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        content: Form(
          key: _passwordFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _oldPasswordController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white10,
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white10,
                ),
                obscureText: true,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white10,
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _changePassword(_passwordFormKey),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(GlobalKey<FormState> formKey) async {
    if (formKey.currentState!.validate() && _userProfile != null) {
      try {
        final result = await _authService.changePassword(
          prn: _userProfile!['prn'],
          oldPassword: _oldPasswordController.text,
          newPassword: _newPasswordController.text,
        );
        Navigator.of(context).pop(); // Close dialog
        if (result['success']) {
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Profile'),
            const Tab(text: 'My Items'),
            Tab(
              child: SizedBox(
                width: 140, // Fixed width to prevent overflow
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text('Contact Requests', textAlign: TextAlign.center),
                    if (_contactRequests.where((r) => r.status == 'pending').isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _contactRequests.where((r) => r.status == 'pending').length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Profile Tab
          _loadingProfile || _userProfile == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.primaryColor,
                        AppConstants.primaryColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      Text(
                        _userProfile!['full_name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'PRN: ${_userProfile!['prn']}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXXLarge),

                // Change Password Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _showChangePasswordDialog,
                    icon: const Icon(Icons.lock, color: Colors.white70),
                    label: const Text('Change Password', style: TextStyle(color: Colors.white70)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXXLarge),

                if (!_isEditing) ...[
                  _buildProfileField(
                    label: 'Full Name',
                    value: _userProfile!['full_name'],
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildProfileField(
                    label: 'Email',
                    value: _userProfile!['email'],
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildProfileField(
                    label: 'Phone Number',
                    value: _userProfile!['phone_number'],
                    icon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildProfileField(
                    label: 'Year of Study',
                    value: 'Year ${_userProfile!['year']}',
                    icon: Icons.school_outlined,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildProfileField(
                    label: 'Branch',
                    value: _userProfile!['branch'],
                    icon: Icons.engineering_outlined,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildProfileField(
                    label: 'Department',
                    value: _userProfile!['department'],
                    icon: Icons.business_outlined,
                  ),
                  const SizedBox(height: AppConstants.paddingXXLarge),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                    ),
                  ),
                ] else ...[
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person, color: Colors.white70),
                            labelStyle: TextStyle(color: Colors.white70),
                            hintStyle: TextStyle(color: Colors.white54),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white10,
                          ),
                          validator: Validators.validateFullName,
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email, color: Colors.white70),
                            labelStyle: TextStyle(color: Colors.white70),
                            hintStyle: TextStyle(color: Colors.white54),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white10,
                          ),
                          validator: Validators.validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        TextFormField(
                          controller: _phoneController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone, color: Colors.white70),
                            labelStyle: TextStyle(color: Colors.white70),
                            hintStyle: TextStyle(color: Colors.white54),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white10,
                          ),
                          validator: Validators.validatePhone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        TextFormField(
                          controller: _yearController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Year of Study',
                            prefixIcon: Icon(Icons.school, color: Colors.white70),
                            labelStyle: TextStyle(color: Colors.white70),
                            hintStyle: TextStyle(color: Colors.white54),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white10,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your year of study';
                            }
                            final year = int.tryParse(value);
                            if (year == null || year < 1 || year > 4) {
                              return 'Please enter a valid year (1-4)';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        TextFormField(
                          controller: _branchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Branch',
                            prefixIcon: Icon(Icons.engineering, color: Colors.white70),
                            labelStyle: TextStyle(color: Colors.white70),
                            hintStyle: TextStyle(color: Colors.white54),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white10,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your branch';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        TextFormField(
                          controller: _departmentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            prefixIcon: Icon(Icons.business, color: Colors.white70),
                            labelStyle: TextStyle(color: Colors.white70),
                            hintStyle: TextStyle(color: Colors.white54),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white10,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your department';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppConstants.paddingXXLarge),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _isEditing = false),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white24),
                                  foregroundColor: Colors.white70,
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: AppConstants.paddingMedium),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // My Items Tab
          _loadingMyItems
              ? const Center(child: CircularProgressIndicator())
              : _myItems.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No items found', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMyItems,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _myItems.length,
                        itemBuilder: (context, index) {
                          final item = _myItems[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: item.imageUrl != null
                                  ? Image.network(
                                      item.imageUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.image_not_supported),
                                    )
                                  : const Icon(Icons.inventory),
                              title: Text(item.title),
                              subtitle: Text(
                                '${item.location} • ${item.createdAt.toString().split(' ')[0]}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteItem(item.id, item.imageUrl),
                              ),
                              onTap: () {
                                // Navigate to item details or edit
                                Navigator.pushNamed(context, '/item-details', arguments: item);
                              },
                            ),
                          );
                        },
                      ),
                    ),

          // Contact Requests Tab
          _loadingRequests
              ? const Center(child: CircularProgressIndicator())
              : _contactRequests.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No contact requests', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadContactRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _contactRequests.length,
                        itemBuilder: (context, index) {
                          final request = _contactRequests[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person, color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Request from ${request.requesterPrn}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: request.status == 'pending'
                                              ? Colors.orange
                                              : request.status == 'approved'
                                                  ? Colors.green
                                                  : Colors.red,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          request.status.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (request.message != null) ...[
                                    Text(
                                      'Message: ${request.message}',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Text(
                                    'Requested on: ${request.createdAt.toString().split(' ')[0]}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                  const SizedBox(height: 12),
                                  if (request.status == 'pending') ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _updateRequestStatus(request.id, 'approved'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            child: const Text('Approve'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _updateRequestStatus(request.id, 'denied'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            child: const Text('Deny'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border.all(
          color: Colors.white10,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: AppConstants.paddingMedium),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}