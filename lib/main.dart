import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/supabase_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';
import 'utils/theme_provider.dart';

/// Main entry point of the application
/// Initializes Supabase and sets up routing

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase (connects to backend)
  try {
    await SupabaseService().initialize();
    print('âœ… App initialization complete');
  } catch (e) {
    print('âŒ Initialization failed: $e');
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

/// Main application widget
/// Sets up theme, routing, and root widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
      title: 'Find-It',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        // Primary color for main UI elements
        primaryColor: AppConstants.primaryColor,
        primarySwatch: const MaterialColor(
          0xFF6366F1,
          <int, Color>{
            50: Color(0xFFF0F4FF),
            100: Color(0xFFE0E7FF),
            200: Color(0xFFC7D2FE),
            300: Color(0xFFA5B4FC),
            400: Color(0xFF818CF8),
            500: Color(0xFF6366F1),
            600: Color(0xFF4F46E5),
            700: Color(0xFF4338CA),
            800: Color(0xFF3730A3),
            900: Color(0xFF312E81),
          },
        ),
        
        // Material Design 3
        useMaterial3: true,
        
        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        // ElevatedButton theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // TextButton theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // InputDecoration theme
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppConstants.primaryColor,
              width: 2,
            ),
          ),
          labelStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),

        // FloatingActionButton theme
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        
        // Chip theme
        chipTheme: ChipThemeData(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),

        // Scaffold background
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        
        // Bottom Sheet theme
        bottomSheetTheme: const BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
        ),
      ),
      
      // Dark theme
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      
      // Home route when user is authenticated
      home: const AuthWrapper(),
      
      // Named routes
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
      },
      
      // Initial route (auth wrapper decides)
      initialRoute: '/',
      
      // Remove debug banner
      debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

/// Widget that decides which screen to show based on authentication status
/// If user is logged in â†’ HomeScreen
/// If user is not logged in â†’ LoginScreen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  
  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();
    
    // Check if user is authenticated
    if (supabaseService.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}