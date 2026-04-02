// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/search_screen.dart'; // Import our newly separated screen

void main() {
  runApp(const LogoScannerApp());
}

class LogoScannerApp extends StatelessWidget {
  const LogoScannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Logo Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SearchScreen(), // Cleanly points to the UI file
    );
  }
}
