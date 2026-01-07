import 'package:flutter/material.dart';
import 'utils/constants.dart';
import 'utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late UserProfile _userProfile;
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _userProfile = UserProfile(
      prn: 'CS12345',
      fullName: 'John Doe',
      email: 'john.doe@college.edu',
      phoneNumber: '9876543210',
      yearOfStudy: '3rd Year',
      branch: 'CSE',
      department: 'Engineering',
    );

    _nameController = TextEditingController(text: _userProfile.fullName);
    _emailController = TextEditingController(text: _userProfile.email);
    _phoneController = TextEditingController(text: _userProfile.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _userProfile = UserProfile(
          prn: _userProfile.prn,
          fullName: _nameController.text,
          email: _emailController.text,
          phoneNumber: _phoneController.text,
          yearOfStudy: _userProfile.yearOfStudy,
          branch: _userProfile.branch,
          department: _userProfile.department,
        );
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppConstants.successColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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
                    AppConstants.primaryColor.withOpacity(0.7),
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
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    _userProfile.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'PRN: ${_userProfile.prn}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingXXLarge), // âœ… FIXED

            if (!_isEditing) ...[
              _buildProfileField(
                label: 'Full Name',
                value: _userProfile.fullName,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildProfileField(
                label: 'Email',
                value: _userProfile.email,
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildProfileField(
                label: 'Phone Number',
                value: _userProfile.phoneNumber,
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildProfileField(
                label: 'Year of Study',
                value: _userProfile.yearOfStudy,
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildProfileField(
                label: 'Branch',
                value: _userProfile.branch,
                icon: Icons.engineering_outlined,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildProfileField(
                label: 'Department',
                value: _userProfile.department,
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: AppConstants.paddingXXLarge), // âœ… FIXED
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
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person,
                            color: AppConstants.primaryColor),
                      ),
                      validator: Validators.validateFullName,
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email,
                            color: AppConstants.primaryColor),
                      ),
                      validator: Validators.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone,
                            color: AppConstants.primaryColor),
                      ),
                      validator: Validators.validatePhone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppConstants.paddingXXLarge), // âœ… FIXED
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _isEditing = false),
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
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 24),
          const SizedBox(width: AppConstants.paddingMedium),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.hintColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppConstants.bodyText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UserProfile {
  final String prn;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String yearOfStudy;
  final String branch;
  final String department;

  UserProfile({
    required this.prn,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.yearOfStudy,
    required this.branch,
    required this.department,
  });
}