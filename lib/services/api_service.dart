// lib/services/api_service.dart
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/logo_match.dart'; // Import our new model

class ApiService {
  // ⚠️ YOUR FLASK SERVER IP ⚠️
  final String serverUrl = 'http://192.168.1.115:5000';

  // 1. Health Check
  Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(Uri.parse(serverUrl)).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 2. Cinematic Mockup function
  Future<List<LogoMatch>> searchLogoMockup({required Function(String) onProgress}) async {
    onProgress("Segmenting logos...");
    await Future.delayed(const Duration(milliseconds: 1200));
    
    onProgress("Extracting feature vectors...");
    await Future.delayed(const Duration(milliseconds: 1200));
    
    onProgress("Searching database...");
    await Future.delayed(const Duration(milliseconds: 1200));

    final fakeResponse = [
      {"brand": "Burger King", "confidence": 98.75, "domain": "Food & Beverage", "logo_url": "https://logo.clearbit.com/burgerking.com"},
      {"brand": "McDonald's", "confidence": 42.10, "domain": "Food & Beverage", "logo_url": "https://logo.clearbit.com/mcdonalds.com"}
    ];

    return fakeResponse.map((data) => LogoMatch.fromJson(data)).toList();
  }
}
