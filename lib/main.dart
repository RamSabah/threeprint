import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'BaseColors.dart';
import 'navigation/Navigation.dart';
import 'pages/account_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// Color Palette
class AppColors {
  static const Color primaryColor = Color(0xFF222831);        // Primary color
  static const Color secondaryDark = Color(0xFF393E46);       // Secondary Dark color
  static const Color specialColor = Color(0xFFF96D00);        // Buttons and title colors
  static const Color secondaryLight = Color(0xFFF2F2F2);      // Secondary Light color
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColors = BaseColors();
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
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
          foregroundColor: AppColors.secondaryDark,
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
      home: const MainNavigation(),
      routes: {
        '/account': (context) => const AccountPage(),
      },
    );
  }
}


