import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';

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
  final FlipCardController _flipController = FlipCardController(); 

  File? _selectedImage;
  bool _isLoading = false;
  String _loadingText = "Analyzing...";
  bool _showSegmentation = false;
  List<LogoMatch> _results = [];
  String? _errorMessage;

  String? _originalImgBase64;
  String? _maskImgBase64;

  bool _isCheckingServer = true; 
  bool _isServerOnline = false;
  bool _usePrototypeMode = false;

  String _selectedScope = 'BOTH';
  int _selectedK = 10;
  String _selectedCategory = 'All'; 
  final List<String> _categories = ['All', 'Food', 'Tech', 'Medical', 'Finance', 'Others'];

  @override
  void initState() {
    super.initState();
    _checkServerStatus();
  }

  Future<void> _checkServerStatus() async {
    setState(() { 
      _isCheckingServer = true; 
      _errorMessage = null; 
      _usePrototypeMode = false;
    });
    bool isOnline = await _apiService.checkServerStatus();
    setState(() {
      _isServerOnline = isOnline;
      _isCheckingServer = false;
    });
  }

  Future<void> _performSearch() async {
    if (_selectedImage == null) return;
    
    setState(() { 
      _isLoading = true; 
      _errorMessage = null; 
      _results = []; 
      _showSegmentation = false;
      _originalImgBase64 = null;
      _maskImgBase64 = null;
    });

    try {
      if (_usePrototypeMode) {
        _results = await _apiService.searchLogoMockup(
          onProgress: (text) => setState(() => _loadingText = text),
        );
      } else {
        final Map<String, dynamic> response = await _apiService.searchLogo(
          imageFile: _selectedImage!,
          scope: _selectedScope,
          topK: _selectedK,
          category: _selectedCategory == 'All' ? '' : _selectedCategory,
          onProgress: (text) => setState(() => _loadingText = text),
        );

        setState(() { 
          _results = response['matches'];
          _originalImgBase64 = response['original_img'];
          _maskImgBase64 = response['mask_img'];
          _showSegmentation = true; 
        });
      }
    } catch (e) {
      setState(() => _errorMessage = "Search Failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() { _selectedImage = File(pickedFile.path); });
        _performSearch();
      }
    } catch (e) {
      setState(() => _errorMessage = "Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingServer) {
      return const Scaffold(backgroundColor: Colors.black87, body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)));
    }

    if (!_isServerOnline && !_usePrototypeMode) {
      return OfflineView(onRetry: _checkServerStatus, onBypass: () => setState(() => _usePrototypeMode = true));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('WonksNet AI Scanner'), centerTitle: true),
      body: Stack(
        children: [
          Column(
            children: [
              ImagePreview(image: _selectedImage, showSegmentation: _showSegmentation),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: _buildDropdownK()),
                    const SizedBox(width: 5),
                    Expanded(flex: 3, child: _buildDropdownScope()),
                    const SizedBox(width: 5),
                    Expanded(flex: 3, child: _buildDropdownCategory()),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              _buildActionButtons(),
              const Divider(height: 10), // Reduced height

              Expanded(
                child: _errorMessage != null 
                  ? _buildErrorWidget()
                  : _results.isEmpty && !_isLoading
                    ? _buildInitialWidget()
                    : ListView.builder(
                        // LUNAS: Dinagdagan ng +1 para sa Heatmap tile
                        itemCount: _results.length + 1, 
                        itemBuilder: (context, index) {
                          // Unang item ay ang Heatmap section
                          if (index == 0) {
                            return _buildCollapsibleHeatmap();
                          }
                          // Ang susunod ay ang actual results, adjusted index
                          final matchIndex = index - 1;
                          return ResultCard(match: _results[matchIndex], isTopMatch: matchIndex == 0);
                        },
                      ),
              ),
            ],
          ),

          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // LUNAS: Ito ay collapsible na ngayon at nasa loob ng scroll view
  Widget _buildCollapsibleHeatmap() {
    if (_originalImgBase64 == null || _maskImgBase64 == null) {
      return const SizedBox.shrink(); // Hide if no data
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0, // Clean look, seamless with scroll
      color: Colors.blueGrey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        key: const PageStorageKey('heatmap_tile'), // Maintains state during scroll
        title: Row(
          children: [
            Icon(Icons.psychology_outlined, color: Colors.blue.shade900, size: 20),
            const SizedBox(width: 10),
            Text(
              "SHOW AI ANALYSIS (Tap Card)",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blue.shade900, letterSpacing: 0.8),
            ),
          ],
        ),
        subtitle: const Text("Tap the result area below to flip between logo and heatmap", style: TextStyle(fontSize: 9, color: Colors.grey)),
        childrenPadding: const EdgeInsets.all(16),
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        children: [
          Center(
            child: Column(
              children: [
                FlipCard(
                  controller: _flipController,
                  rotateSide: RotateSide.bottom,
                  onTapFlipping: true,
                  frontWidget: _buildAnalysisFace(_originalImgBase64!, "INPUT LOGO", Colors.blue),
                  backWidget: _buildAnalysisFace(_maskImgBase64!, "HEATMAP MASK", Colors.redAccent),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisFace(String base64Str, String label, Color accent) {
    return Container(
      width: 180, // Slightly bigger, seamless in ExpansionTile
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withOpacity(0.5), width: 2),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.memory(base64Decode(base64Str), fit: BoxFit.contain, width: 180, height: 180),
          ),
          Positioned(
            top: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4)),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // Helper UI Widgets to keep build clean
  Widget _buildDropdownK() => DropdownButtonFormField<int>(value: _selectedK, items: [5, 10, 25].map((k) => DropdownMenuItem(value: k, child: Text("$k"))).toList(), onChanged: (v) => setState(() => _selectedK = v!), decoration: const InputDecoration(labelText: "Top K"));
  Widget _buildDropdownScope() => DropdownButtonFormField<String>(value: _selectedScope, items: ['PH', 'GLOBAL', 'BOTH'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _selectedScope = v!), decoration: const InputDecoration(labelText: "Scope"));
  Widget _buildDropdownCategory() => DropdownButtonFormField<String>(value: _selectedCategory, items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _selectedCategory = v!), decoration: const InputDecoration(labelText: "Category"));
  
  Widget _buildActionButtons() => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
    ElevatedButton.icon(onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Camera')),
    ElevatedButton.icon(onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Gallery')),
    CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: IconButton(onPressed: (_selectedImage != null && !_isLoading) ? _performSearch : null, icon: const Icon(Icons.refresh, color: Colors.blue))),
  ]);

  Widget _buildInitialWidget() => const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("WonksNet Wonks! Scan a logo to begin AI analysis.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))));
  Widget _buildErrorWidget() => Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))));
  Widget _buildLoadingOverlay() => Container(color: Colors.black.withOpacity(0.6), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(color: Colors.greenAccent), const SizedBox(height: 20), Text(_loadingText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])));
}
