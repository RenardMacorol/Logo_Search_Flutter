// lib/screens/search_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/logo_match.dart';
import '../services/api_service.dart';
import '../widgets/result_card.dart';
import '../widgets/offline_view.dart';
import '../widgets/image_preview.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = false;
  String _loadingText = "Analyzing...";
  bool _showSegmentation = false;
  List<LogoMatch> _results = [];
  String? _errorMessage;

  bool _isCheckingServer = true; 
  bool _isServerOnline = false;
  bool _usePrototypeMode = false;

  @override
  void initState() {
    super.initState();
    _checkServerStatus();
  }

  Future<void> _checkServerStatus() async {
    setState(() { _isCheckingServer = true; _errorMessage = null; });
    await Future.delayed(const Duration(milliseconds: 1500));
    bool isOnline = await _apiService.checkServerStatus();
    
    setState(() {
      _isServerOnline = isOnline;
      _isCheckingServer = false;
      if (isOnline) _usePrototypeMode = false; 
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _results = [];
          _errorMessage = null;
          _showSegmentation = false;
          _isLoading = true;
        });

        final results = await _apiService.searchLogoMockup(
          onProgress: (text) => setState(() => _loadingText = text),
        );

        setState(() {
          _results = results;
          _showSegmentation = true;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. STARTUP SCREEN
    if (_isCheckingServer) {
      return const Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.greenAccent),
              SizedBox(height: 24),
              Text("Connecting to AI Backend...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    // 2. OFFLINE SCREEN (Using our new widget!)
    if (!_isServerOnline && !_usePrototypeMode) {
      return OfflineView(
        onRetry: _checkServerStatus,
        onBypass: () => setState(() => _usePrototypeMode = true),
      );
    }

    // 3. MAIN UI
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logo Scanner AI', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(_usePrototypeMode ? Icons.warning_amber_rounded : Icons.check_circle, color: _usePrototypeMode ? Colors.orange : Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(_usePrototypeMode ? "Mock Mode" : "Online", style: TextStyle(color: _usePrototypeMode ? Colors.orange : Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Using our new widget!
              ImagePreview(image: _selectedImage, showSegmentation: _showSegmentation),
              
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Camera')),
                  ElevatedButton.icon(onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Gallery')),
                ],
              ),
              const Divider(height: 32),
              Expanded(
                child: _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) => ResultCard(match: _results[index], isTopMatch: index == 0),
                      ),
              ),
            ],
          ),
          
          // Cinematic Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.greenAccent),
                    const SizedBox(height: 24),
                    Text(_loadingText, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 1.2)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
