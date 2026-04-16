	// ip addr show | grep inet use this command
	//flutter run -d web-server --web-hostname 1.0.0.0 --web-port 5001
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; 
import '../models/logo_match.dart';

class ApiService {
  // 🟢 IP Address ng Flask server
  // Paalala: Siguraduhin na ang mobile device at PC ay nasa iisang Wi-Fi network.
  final String serverUrl = 'http://127.0.0.1:5000'; 

  // --- 1. HEALTH CHECK ---
  Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(Uri.parse(serverUrl))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("🔴 Server Offline: $e");
      return false;
    }
  }

  // --- 2. GALAXY/DISCOVERY ENGINE ---
  Future<List<dynamic>> getGalaxyPoints({String scope = 'BOTH'}) async {
    try {
      final queryParams = '?scope=$scope&industry=All';
      final response = await http.get(
        Uri.parse('$serverUrl/api/discovery$queryParams'),
      ).timeout(const Duration(seconds: 25)); 

      if (response.statusCode == 200) {
        // Ginagamit ang 'compute' para hindi mag-lag ang UI sa malaking JSON data
        return await compute(_parseGalaxyJson, response.body);
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("🔴 Galaxy API Error: $e");
      rethrow;
    }
  }

  // --- 3. SEARCH ENGINE (MOBILE & WEB HYBRID) ---
  Future<Map<String, dynamic>> searchLogo({
    File? imageFile,          // Para sa Android/iOS
    Uint8List? webImageBytes, // Para sa Web
    required Function(String) onProgress,
    String scope = 'BOTH',
    int topK = 10,
    String category = '',
    String sortBy = 'confidence',
  }) async {
    try {
      onProgress("Preparing Image...");
      var request = http.MultipartRequest('POST', Uri.parse('$serverUrl/api/predict'));

      // Handling Image Upload base sa Platform
      if (kIsWeb) {
        if (webImageBytes == null) throw Exception("Missing image bytes for web upload");
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          webImageBytes,
          filename: 'upload.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      } else {
        if (imageFile == null) throw Exception("Missing file for mobile upload");
        request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      }

      // Payload Fields
      request.fields['scope'] = scope;
      request.fields['top_k'] = topK.toString();
      request.fields['sort_by'] = sortBy;
      
      if (category.isNotEmpty && category != 'All') {
        request.fields['category'] = category;
      }

      onProgress("AI Analysis in progress...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        onProgress("Finalizing results...");
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'success') {
          // Kunin ang listahan ng predictions
          final List<dynamic> predictions = data['predictions'] ?? [];
          
          return {
            // 🟢 CRITICAL: Dito natin pino-process ang bawat match.
            // Ang LogoMatch.fromJson na ang bahalang kumuha ng forensic_viz at orb_similarity.
            "matches": predictions.map((item) => LogoMatch.fromJson(item)).toList(),
            
            // Mga base64 images para sa AI Vision Analysis section (Heatmap/Input)
            "original_img": data['original_img_base64'], 
            "mask_img": data['mask_img_base64'],
            
            // Meta data para sa status bar
            "latent_map": data['latent_map'],
            "total_found": data['total_found'] ?? 0,
            "meta": data['meta'] ?? {},
          };
        } else {
          throw Exception(data['message'] ?? "Unknown API Error");
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("🔴 Flutter API Error: $e");
      rethrow;
    }
  }

  // --- 4. MOCKUP MODE (For Testing) ---
  Future<List<LogoMatch>> searchLogoMockup({required Function(String) onProgress}) async {
    onProgress("Simulating...");
    await Future.delayed(const Duration(seconds: 2));
    return [
      LogoMatch(
        brandName: "Mockup Brand", 
        confidence: 0.985, 
        domain: "Technology", 
        logoUrl: "", 
        stability: "Strong Contender",
        orbSimilarity: 92.0,
      ),
    ];
  }
}

// --- GLOBAL HELPERS (Dapat nasa labas ng class para sa 'compute') ---

List<dynamic> _parseGalaxyJson(String responseBody) {
  final Map<String, dynamic> decoded = json.decode(responseBody);
  return decoded['points'] as List<dynamic>? ?? [];
}
