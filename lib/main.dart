// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/search_screen.dart'; // Import our newly separated screen
import 'screens/home_screen.dart'; // Import our newly separated screen

void main() {
  // Lock landscape only when needed, but for now allow both
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LogoScannerApp());
}

class LogoScannerApp extends StatelessWidget {
  const LogoScannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WonksNet AI',
      theme: ThemeData(
        brightness: Brightness.dark, // Dark mode para futuristic
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(), 
    );
  }
}
