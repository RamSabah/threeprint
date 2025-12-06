import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'BaseColors.dart';
import 'navigation/Navigation.dart';
import 'pages/account_page.dart';

void main() async {
  // Wrap the entire main function in error handling
  runZonedGuarded(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      
      // Minimal delay for faster startup
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Initialize Firebase with better error handling
      bool firebaseInitialized = false;
      try {
        // Always check Firebase apps status
        final existingApps = Firebase.apps;
        if (existingApps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          firebaseInitialized = true;
          print('Firebase initialized successfully');
        } else {
          // Firebase already initialized, check if it's working
          firebaseInitialized = true;
          print('Firebase already initialized with ${existingApps.length} apps');
        }
      } catch (e) {
        print('Error initializing Firebase: $e');
        firebaseInitialized = false;
        // Continue without Firebase if initialization fails
      }
      
      // Store Firebase status globally
      runApp(MyApp(firebaseInitialized: firebaseInitialized));
      
    } catch (e, stack) {
      print('Error in main initialization: $e');
      print('Stack trace: $stack');
      // Run app with minimal configuration if there's an error
      runApp(const MyApp(firebaseInitialized: false));
    }
  }, (error, stack) {
    print('Uncaught error in main: $error');
    print('Stack trace: $stack');
    // Last resort - run app with basic configuration
    try {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const MyApp(firebaseInitialized: false));
    } catch (e) {
      print('Fatal error: $e');
    }
  });
}

// Color Palette
class AppColors {
  static const Color primaryColor = Color(0xFF222831);        // Primary color
  static const Color secondaryDark = Color(0xFF393E46);       // Secondary Dark color
  static const Color specialColor = Color(0xFFF96D00);        // Buttons and title colors
  static const Color secondaryLight = Color(0xFFF2F2F2);      // Secondary Light color
}

class MyApp extends StatefulWidget {
  final bool firebaseInitialized;
  
  const MyApp({super.key, this.firebaseInitialized = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isAppReady = false;
  
  @override
  void initState() {
    super.initState();
    
    // Add app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      print('Flutter error: ${details.exception}');
      print('Stack trace: ${details.stack}');
    };
    
    // iPhone X specific optimizations
    _initializeApp();
  }
  
  @override
  void dispose() {
    // Clean up lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('App resumed');
        // Re-initialize if needed when app comes back to foreground
        if (!_isAppReady) {
          _initializeApp();
        }
        break;
      case AppLifecycleState.paused:
        print('App paused');
        break;
      case AppLifecycleState.detached:
        print('App detached');
        break;
      case AppLifecycleState.inactive:
        print('App inactive');
        break;
      case AppLifecycleState.hidden:
        print('App hidden');
        break;
    }
  }
  
  void _initializeApp() async {
    try {
      // Much shorter delay for faster startup
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Ensure everything is loaded before showing the app
      if (mounted) {
        setState(() {
          _isAppReady = true;
        });
      }
    } catch (e) {
      print('Error during app initialization: $e');
      if (mounted) {
        setState(() {
          _isAppReady = true; // Show app even if there's an error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColors = BaseColors();
    
    // Show minimal loading screen while app initializes
    if (!_isAppReady) {
      return MaterialApp(
        title: 'ThreePrint',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.secondaryLight,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ThreePrint',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.specialColor,
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return MaterialApp(
      title: 'ThreePrint',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Scaffold(
            backgroundColor: AppColors.secondaryLight,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.specialColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please restart the app',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        };
        return child ?? Container();
      },
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryColor,
          secondary: AppColors.specialColor,
          surface: AppColors.secondaryLight,
          onPrimary: AppColors.secondaryDark,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.secondaryLight,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.specialColor,
            foregroundColor: AppColors.secondaryLight,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.specialColor,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
        ),
      ),
      home: const SafeAreaWrapper(),
      routes: {
        '/account': (context) => const AccountPage(),
      },
    );
  }
}

class SafeAreaWrapper extends StatefulWidget {
  const SafeAreaWrapper({super.key});

  @override
  State<SafeAreaWrapper> createState() => _SafeAreaWrapperState();
}

class _SafeAreaWrapperState extends State<SafeAreaWrapper> {
  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSafely();
  }
  
  void _initializeSafely() async {
    try {
      // Minimal delay for faster startup
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in SafeAreaWrapper initialization: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildErrorWidget() {
    return Scaffold(
      backgroundColor: AppColors.secondaryLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.specialColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'App Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'There was an issue starting the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.secondaryDark,
                  ),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorMessage = '';
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.secondaryLight,
        body: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: AppColors.specialColor,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    try {
      return const MainNavigation();
    } catch (e, stackTrace) {
      print('Error loading MainNavigation: $e');
      print('Stack trace: $stackTrace');
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = e.toString();
          });
        }
      });
      
      return _buildErrorWidget();
    }
  }
}


