import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/logo_match.dart';

class ApiService {
  final String serverUrl = 'http://192.168.1.108:5000'; // Siguraduhing tama ang IP mo

  // Health Check
  Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(Uri.parse(serverUrl))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Real API Search Engine
  Future<Map<String, dynamic>> searchLogo({
    required File imageFile,
    required Function(String) onProgress,
    String scope = 'BOTH',
    int topK = 10,
    String category = '',
    String sortBy = 'confidence',
  }) async {
    try {
      onProgress("Uploading & Processing Image...");
      var request = http.MultipartRequest('POST', Uri.parse('$serverUrl/api/predict'));

      // Attach file
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      // Attach dynamic filters
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
            "original_img": data['original_img_base64'], // Front display image
            "mask_img": data['mask_img_base64'],         // Back display image (Heatmap)
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

  // Mockup Mode for Testing
  Future<List<LogoMatch>> searchLogoMockup({
    required Function(String) onProgress,
  }) async {
    onProgress("Simulating AI Inference...");
    await Future.delayed(const Duration(seconds: 2));
    return [
      LogoMatch(brandName: "Mockup - Nike", confidence: 98.5, domain: "Sports", logoUrl: "", stability: "Strong"),
      LogoMatch(brandName: "Mockup - Adidas", confidence: 85.2, domain: "Apparel", logoUrl: "", stability: "Moderate"),
    ];
  }
}
