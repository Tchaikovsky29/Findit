import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/config.dart';
import 'utils/constants.dart';
import 'utils/theme_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===== VALIDATE & LOAD CONFIGURATION =====
  try {
    AppConfig.validateConfig();
  } catch (e) {
    debugPrint('âš ï¸ Configuration Error: $e');
    debugPrint('Please follow the setup guide in README.md');
    rethrow;
  }

  // ===== INITIALIZE SUPABASE WITH SECURE CONFIG =====
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    debugPrint('âœ… Supabase initialized successfully');
  } catch (e) {
    debugPrint('âŒ Supabase initialization failed: $e');
    rethrow;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const FindItApp(),
    ),
  );
}

class FindItApp extends StatelessWidget {
  const FindItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          home: _buildHome(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppConstants.primaryColor,
      brightness: Brightness.light,
      // ... rest of theme config
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppConstants.primaryColor,
      brightness: Brightness.dark,
      // ... rest of theme config
    );
  }

  Widget _buildHome() {
    final user = Supabase.instance.client.auth.currentUser;
    return user == null ? const LoginScreen() : const HomeScreen();
  }
}