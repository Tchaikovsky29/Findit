import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/constants.dart';
import 'utils/theme_provider.dart';
import 'utils/validators.dart';
// import 'utils/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late Map<String, dynamic> _userProfile;
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    // Mock user data - Replace with Supabase fetch
    _userProfile = {
      'prn': 'CS12345',
      'full_name': 'John Doe',
      'email': 'john.doe@college.edu',
      'phone_number': '9876543210',
      'year': 3,
      'branch': 'CSE',
      'department': 'Engineering',
      'theme_preference': 'light',
    };

    _nameController = TextEditingController(text: _userProfile['full_name']);
    _emailController = TextEditingController(text: _userProfile['email']);
    _phoneController = TextEditingController(text: _userProfile['phone_number']);
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
        _userProfile['full_name'] = _nameController.text;
        _userProfile['email'] = _emailController.text;
        _userProfile['phone_number'] = _phoneController.text;
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
                    _userProfile['full_name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'PRN: ${_userProfile['prn']}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingXXLarge),

            // Theme Toggle
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.grey[50],
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette),
                      SizedBox(width: AppConstants.paddingMedium),
                      Text(
                        'Dark Theme',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) => Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) {
                        themeProvider.toggleTheme();
                        // Update Supabase
                        // SupabaseService.updateThemePreference(
                        //   _userProfile['prn'],
                        //   themeProvider.isDarkMode ? 'dark' : 'light',
                        // );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingXXLarge),

            if (!_isEditing) ...[
              _buildProfileField(
                label: 'Full Name',
                value: _userProfile['full_name'],
                icon: Icons.person_outline,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildProfileField(
                label: 'Email',
                value: _userProfile['email'],
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildProfileField(
                label: 'Phone Number',
                value: _userProfile['phone_number'],
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildProfileField(
                label: 'Year of Study',
                value: 'Year ${_userProfile['year']}',
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildProfileField(
                label: 'Branch',
                value: _userProfile['branch'],
                icon: Icons.engineering_outlined,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildProfileField(
                label: 'Department',
                value: _userProfile['department'],
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
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: Validators.validateFullName,
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: Validators.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: Validators.validatePhone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppConstants.paddingXXLarge),
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
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[50],
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[300]!,
        ),
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