import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Import para sa 'compute' at 'kIsWeb'
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Import para sa MediaType (Web support)
import '../models/logo_match.dart';

class ApiService {
  // IP Address ng iyong Flask server. 
  // Paalala: Sa Web, siguruhing ang Flask ay naka-CORS enabled.
	// ip addr show | grep inet use this command
	//flutter run -d web-server --web-hostname 1.0.0.0 --web-port 5001
  final String serverUrl = 'http://192.168.1.108:5000'; 

  // 1. Health Check
  Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(Uri.parse(serverUrl))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      print("🔴 Server Offline: $e");
      return false;
    }
  }

  // 2. Galaxy/Discovery Engine (Supports Large Data via Compute)
  Future<List<dynamic>> getGalaxyPoints({String scope = 'BOTH'}) async {
    try {
      final queryParams = '?scope=$scope&industry=All';
      final response = await http.get(
        Uri.parse('$serverUrl/api/discovery$queryParams'),
      ).timeout(const Duration(seconds: 25)); 

      if (response.statusCode == 200) {
        return await compute(_parseGalaxyJson, response.body);
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("🔴 Galaxy API Error: $e");
      rethrow;
    }
  }

  // 3. Real API Search Engine (HYBRID: Android/iOS/Web)
  Future<Map<String, dynamic>> searchLogo({
    File? imageFile,          // Gagamitin sa Mobile (dart:io)
    Uint8List? webImageBytes, // Gagamitin sa Web (dart:typed_data)
    required Function(String) onProgress,
    String scope = 'BOTH',
    int topK = 10,
    String category = '',
    String sortBy = 'confidence',
  }) async {
    try {
      onProgress("Preparing Image...");
      var request = http.MultipartRequest('POST', Uri.parse('$serverUrl/api/predict'));

      // --- WEB VS MOBILE IMAGE HANDLING ---
      if (kIsWeb) {
        if (webImageBytes == null) throw Exception("Missing image bytes for web upload");
        
        // Pag Web, bytes ang pinapasa sa Multipart
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          webImageBytes,
          filename: 'upload.jpg',
          contentType: MediaType('image', 'jpeg'), // Kailangan ito para mabasa ng Flask
        ));
      } else {
        if (imageFile == null) throw Exception("Missing file for mobile upload");
        
        // Pag Mobile, path ang ginagamit
        request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      }

      // --- ATTACH FIELDS ---
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
          List<dynamic> predictions = data['predictions'];
          
          return {
            "matches": predictions.map((json) => LogoMatch.fromJson(json)).toList(),
            "original_img": data['original_img_base64'], 
            "mask_img": data['mask_img_base64'],
            "latent_map": data['latent_map'],
            "total_found": data['total_found'],
            "meta": data['meta'],
          };
        } else {
          throw Exception(data['message'] ?? "Unknown API Error");
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("🔴 Flutter API Error: $e");
      rethrow;
    }
  }

  // 4. Mockup Mode
  Future<List<LogoMatch>> searchLogoMockup({required Function(String) onProgress}) async {
    onProgress("Simulating...");
    await Future.delayed(const Duration(seconds: 2));
    return [
      LogoMatch(brandName: "Mockup - Nike", confidence: 98.5, domain: "Sports", logoUrl: "", stability: "Strong"),
    ];
  }
}

// --- GLOBAL HELPER (Dapat nasa labas ng class para sa 'compute') ---

List<dynamic> _parseGalaxyJson(String responseBody) {
  final Map<String, dynamic> decoded = json.decode(responseBody);
  return decoded['points'] as List<dynamic>? ?? [];
}
