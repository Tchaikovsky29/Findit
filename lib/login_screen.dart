import 'package:flutter/material.dart';
import 'utils/constants.dart';
import 'utils/validators.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _prnController;
  late TextEditingController _passwordController;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _prnController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _prnController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login successful! Welcome ${_prnController.text}'),
            backgroundColor: AppConstants.successColor,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pushReplacementNamed('/home');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: AppConstants.paddingLarge,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppConstants.paddingXXLarge), // âœ… FIXED

              Text(
                AppConstants.appName,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                AppConstants.appTagline,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppConstants.hintColor,
                ),
              ),
              const SizedBox(height: AppConstants.paddingXXLarge), // âœ… FIXED

              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.loginTitle,
                      style: AppConstants.heading2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.loginSubtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConstants.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingXXLarge), // âœ… FIXED

              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _prnController,
                      decoration: const InputDecoration(
                        labelText: 'PRN (College Roll Number)',
                        prefixIcon: Icon(Icons.badge, color: AppConstants.primaryColor),
                        hintText: 'Enter your PRN',
                      ),
                      validator: Validators.validatePRN,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),

                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock, color: AppConstants.primaryColor),
                        hintText: 'Enter your password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppConstants.hintColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingXXLarge), // âœ… FIXED

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
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
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingXXLarge), // âœ… FIXED

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Don\'t have an account? ',
                    style: TextStyle(color: AppConstants.hintColor),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}