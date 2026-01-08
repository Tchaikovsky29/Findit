import 'package:flutter/material.dart';
import 'utils/constants.dart';
import 'utils/validators.dart';
// import 'utils/supabase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
  final List<String> _branchOptions = ['CSE', 'ECE', 'Mechanical', 'Civil', 'Electrical'];
  final List<String> _departmentOptions = ['Engineering', 'Science', 'Arts', 'Commerce'];

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prnController = TextEditingController();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _prnController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedYear == null || _selectedBranch == null || _selectedDepartment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select year, branch, and department'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Uncomment to use Supabase
        // final success = await SupabaseService.registerUser(
        //   prn: _prnController.text,
        //   password: _passwordController.text,
        //   fullName: _nameController.text,
        //   year: int.parse(_selectedYear!),
        //   branch: _selectedBranch!,
        //   department: _selectedDepartment!,
        //   phone: _phoneController.text,
        //   email: _emailController.text,
        // );

        // Mock registration
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: AppConstants.successColor,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } catch (e) {
        setState(() => _errorMessage = 'Registration failed: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
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

              TextFormField(
                controller: _prnController,
                decoration: const InputDecoration(
                  labelText: 'PRN (College Roll Number)',
                  prefixIcon: Icon(Icons.badge),
                  hintText: 'e.g., CS12345',
                ),
                validator: Validators.validatePRN,
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Enter your full name',
                ),
                validator: Validators.validateFullName,
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                  hintText: 'your.email@college.edu',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '10-digit phone number',
                ),
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              DropdownButtonFormField<String>(
                initialValue: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Year of Study',
                  prefixIcon: Icon(Icons.school),
                ),
                items: _yearOptions
                    .map((year) => DropdownMenuItem(
                          value: year,
                          child: Text('Year $year'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedYear = value),
                validator: (value) =>
                    value == null ? 'Please select a year' : null,
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              DropdownButtonFormField<String>(
                initialValue: _selectedBranch,
                decoration: const InputDecoration(
                  labelText: 'Branch',
                  prefixIcon: Icon(Icons.engineering),
                ),
                items: _branchOptions
                    .map((branch) => DropdownMenuItem(
                          value: branch,
                          child: Text(branch),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedBranch = value),
                validator: (value) =>
                    value == null ? 'Please select a branch' : null,
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.business),
                ),
                items: _departmentOptions
                    .map((dept) => DropdownMenuItem(
                          value: dept,
                          child: Text(dept),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedDepartment = value),
                validator: (value) =>
                    value == null ? 'Please select a department' : null,
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  hintText: 'Min 8 characters, 1 uppercase, 1 number',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock),
                  hintText: 'Re-enter your password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) =>
                    Validators.validatePasswordConfirmation(
                  value,
                  _passwordController.text,
                ),
              ),
              const SizedBox(height: AppConstants.paddingXXLarge),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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
              const SizedBox(height: AppConstants.paddingMedium),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Already have an account? Sign in',
                    style: TextStyle(color: AppConstants.primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}