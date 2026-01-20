import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../services/auth_service.dart';

/// Modern Signup Screen
/// Professional registration interface with multi-step form
/// Includes validation, accessibility, and responsive design

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _prnController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  String? _selectedYear;
  String? _selectedBranch;
  String? _selectedDepartment;

  final List<String> _yearOptions = ['1', '2', '3', '4'];
  final List<String> _branchOptions = ['CSE', 'ECE', 'Mechanical', 'Civil', 'Electrical', 'CSBS'];
  final List<String> _departmentOptions = ['Engineering', 'Science', 'Arts', 'Commerce'];

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _prnController = TextEditingController();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _prnController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedYear == null || _selectedBranch == null || _selectedDepartment == null) {
      _showSnackBar('Please select year, branch, and department', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final yearNumber = int.parse(_selectedYear!.split(' ')[1]);
      final result = await authService.signup(
        prn: _prnController.text.trim().toUpperCase(),
        password: _passwordController.text,
        fullName: _nameController.text,
        year: yearNumber,
        branch: _selectedBranch!,
        department: _selectedDepartment!,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
      );

      if (mounted) {
        if (result['success']) {
          _showSnackBar(result['message'], isSuccess: true);
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          setState(() => _errorMessage = result['message']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Registration failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppConstants.successColor : AppConstants.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a), // Lighter dark background
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppConstants.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                      border: Border.all(color: AppConstants.errorColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: AppConstants.errorColor),
                        const SizedBox(width: AppConstants.paddingMedium),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppConstants.errorColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                ],

                _buildTextField(
                  controller: _prnController,
                  label: 'PRN (College Roll Number)',
                  hint: 'e.g., CS12345',
                  icon: Icons.badge_outlined,
                  validator: Validators.validatePRN,
                  textCapitalization: TextCapitalization.characters,
                ),

                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                  validator: Validators.validateFullName,
                ),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'your.email@college.edu',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),

                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '10-digit phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                ),

                _buildDropdownField(
                  value: _selectedYear,
                  label: 'Year of Study',
                  icon: Icons.school_outlined,
                  items: _yearOptions.map((year) => 'Year $year').toList(),
                  onChanged: (value) => setState(() => _selectedYear = value),
                  validator: (value) => value == null ? 'Please select a year' : null,
                ),

                _buildDropdownField(
                  value: _selectedBranch,
                  label: 'Branch',
                  icon: Icons.engineering_outlined,
                  items: _branchOptions,
                  onChanged: (value) => setState(() => _selectedBranch = value),
                  validator: (value) => value == null ? 'Please select a branch' : null,
                ),

                _buildDropdownField(
                  value: _selectedDepartment,
                  label: 'Department',
                  icon: Icons.business_outlined,
                  items: _departmentOptions,
                  onChanged: (value) => setState(() => _selectedDepartment = value),
                  validator: (value) => value == null ? 'Please select a department' : null,
                ),

                _buildPasswordField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Min 8 characters, 1 uppercase, 1 number',
                  obscure: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: Validators.validatePassword,
                ),

                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  obscure: _obscureConfirmPassword,
                  onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  validator: (value) => Validators.validatePasswordConfirmation(
                    value,
                    _passwordController.text,
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        enabled: !_isLoading,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.white70),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          filled: true,
          fillColor: Colors.white10,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        style: const TextStyle(color: Colors.white),
        dropdownColor: AppConstants.surfaceColor,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.white70),
          labelStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          filled: true,
          fillColor: Colors.white10,
        ),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item, style: const TextStyle(color: Colors.white)),
        )).toList(),
        onChanged: _isLoading ? null : onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        enabled: !_isLoading,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
            ),
            onPressed: onToggle,
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          filled: true,
          fillColor: Colors.white10,
        ),
        validator: validator,
      ),
    );
  }
}