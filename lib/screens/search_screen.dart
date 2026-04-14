import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';

import '../services/api_service.dart';
import '../models/logo_match.dart';
import '../widgets/result_card.dart';
import '../widgets/image_preview.dart';
import '../widgets/latent_map_dialog.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final FlipCardController _flipController = FlipCardController(); 
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;       
  Uint8List? _webImageBytes;  

  bool _isLoading = false;
  String _loadingText = "AI is thinking...";
  List<LogoMatch> _results = [];
  String? _originalImg64, _maskImg64, _errorMessage;
  
  String _selectedScope = 'BOTH';
  int _selectedK = 10;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Food', 'Tech', 'Medical', 'Finance', 'Others'];

  dynamic _latentData;
  Map<String, dynamic>? _meta;
  int _totalFound = 0;

  Future<void> _performSearch() async {
    if (kIsWeb && _webImageBytes == null) return;
    if (!kIsWeb && _selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _results = [];
    });

    try {
      final res = await _apiService.searchLogo(
        imageFile: kIsWeb ? null : _selectedImage,
        webImageBytes: kIsWeb ? _webImageBytes : null,
        scope: _selectedScope,
        topK: _selectedK,
        category: _selectedCategory == 'All' ? '' : _selectedCategory,
        onProgress: (text) => setState(() => _loadingText = text),
      );

      setState(() {
        _results = res['matches'];
        _originalImg64 = res['original_img'];
        _maskImg64 = res['mask_img'];
        _latentData = res['latent_map'];
        _totalFound = res['total_found'] ?? 0;
        _meta = res['meta'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Search Failed: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() { _webImageBytes = bytes; });
      } else {
        setState(() { _selectedImage = File(pickedFile.path); });
      }
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('WonksNet AI Scanner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildImagePreview(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Flexible(flex: 2, child: _buildDropdownK()),
                    const SizedBox(width: 4),
                    Flexible(flex: 3, child: _buildDropdownScope()),
                    const SizedBox(width: 4),
                    Flexible(flex: 4, child: _buildDropdownCategory()),
                  ],
                ),
              ),
              _buildActionRow(),
              if (_results.isNotEmpty) _buildMetaInfoBar(),
              const Divider(color: Colors.white10, height: 1),
              Expanded(
                child: _errorMessage != null 
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)))
                  : ListView.builder(
                      itemCount: _results.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) return _buildHeatmapSection();
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

  Widget _buildImagePreview() {
    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.black26,
      child: kIsWeb 
        ? (_webImageBytes != null ? Image.memory(_webImageBytes!, fit: BoxFit.contain) : _noImagePlaceholder())
        : (_selectedImage != null ? Image.file(_selectedImage!, fit: BoxFit.contain) : _noImagePlaceholder()),
    );
  }

  Widget _noImagePlaceholder() => const Center(child: Icon(Icons.image_search, color: Colors.white10, size: 60));

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btn(Icons.camera_alt, "Camera", () => _pickImage(ImageSource.camera)),
          _btn(Icons.photo_library, "Gallery", () => _pickImage(ImageSource.gallery)),
          IconButton(
            onPressed: ((_selectedImage != null || _webImageBytes != null) && !_isLoading) ? _performSearch : null, 
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E2E), foregroundColor: Colors.white),
    );
  }

  Widget _buildMetaInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blueAccent.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("TTA: ${(_meta?['tta_enabled'] == true) ? 'ACTIVE' : 'OFF'}", 
              style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
          Text("$_totalFound Matches", style: const TextStyle(color: Colors.white70, fontSize: 10)),
          if (_latentData != null)
            ActionChip(
              backgroundColor: const Color(0xFF1E1E2E),
              label: const Text("LATENT MAP", style: TextStyle(fontSize: 9, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              onPressed: () => showDialog(context: context, builder: (c) => LatentMapDialog(queryPoint: _latentData, matches: _results)),
            ),
        ],
      ),
    );
  }

  Widget _buildHeatmapSection() {
    if (_originalImg64 == null || _maskImg64 == null) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.all(12),
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: const Text("AI VISION ANALYSIS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: GestureDetector(
              onTap: () => _flipController.flipcard(), // FIXED: Lowercase 'c' for v0.0.6
              child: FlipCard(
                rotateSide: RotateSide.bottom,
                controller: _flipController,
                frontWidget: _analysisBox(_originalImg64!, "INPUT (Original)"),
                backWidget: _analysisBox(_maskImg64!, "HEATMAP (Segmentation)"),
              ),
            ),
          ),
          const Text("Tap image to flip", style: TextStyle(color: Colors.white24, fontSize: 9)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _analysisBox(String b64, String label) => Container(
    height: 200, width: 200,
    decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12), color: Colors.black),
    child: Stack(children: [
      Center(child: ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.memory(base64Decode(b64), fit: BoxFit.contain))),
      Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.all(4), color: Colors.black54, child: Text(label, style: const TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold)))),
    ]),
  );

  Widget _buildDropdownK() => _drop<int>(_selectedK, [5, 10, 25], "Top K", (v) => setState(() => _selectedK = v!));
  Widget _buildDropdownScope() => _drop<String>(_selectedScope, ['PH', 'GLOBAL', 'BOTH'], "Scope", (v) => setState(() => _selectedScope = v!));
  Widget _buildDropdownCategory() => _drop<String>(_selectedCategory, _categories, "Category", (v) => setState(() => _selectedCategory = v!));

  Widget _drop<T>(T value, List<T> items, String label, Function(T?) onChanged) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      dropdownColor: const Color(0xFF1E1E2E),
      style: const TextStyle(color: Colors.white, fontSize: 10),
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 9), 
        contentPadding: const EdgeInsets.symmetric(horizontal: 8), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toString(), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildLoadingOverlay() => Container(
    color: Colors.black87, 
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(color: Colors.blueAccent), const SizedBox(height: 20), Text(_loadingText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
  );
}
