import 'package:flutter/material.dart';
import '../utils/config.dart';
import '../utils/supabase_service.dart';

class AdminPanel extends StatefulWidget {
  final String userPRN;

  const AdminPanel({super.key, required this.userPRN});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await SupabaseService.isUserAdmin(widget.userPRN);
    setState(() => _isAdmin = isAdmin);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('Access Denied: Admin privileges required'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Admin Email'),
              subtitle: Text(AppConfig.adminEmail),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Admin PRN'),
              subtitle: Text(AppConfig.adminPRN),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('App Version'),
              subtitle: Text(AppConfig.appVersion),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _initializeAdmin(),
            child: const Text('Initialize/Reset Admin User'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeAdmin() async {
    final success = await SupabaseService.initializeAdmin();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Admin initialized successfully'
                : 'Failed to initialize admin',
          ),
        ),
      );
    }
  }
}