import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'BaseColors.dart';
import 'navigation/main_navigation.dart';
import 'pages/account_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF50586C), // Dark blue-gray color as requested
          secondary: const Color(0xFFFFFFFF),
        ),
      ),
      home: const MainNavigation(),
      routes: {
        '/account': (context) => const AccountPage(),
      },
    );
  }
}


