import 'dart:convert';
import 'dart:io';
import 'dart:async'; // 👈 Needed for connection timeouts
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // 👈 Needed to ping the server

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
      home: const SearchScreen(),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  String _loadingText = "Analyzing...";
  bool _showSegmentation = false;
  List<dynamic> _results = [];
  String? _errorMessage;

  // --- 🌐 NEW: SERVER STATUS VARIABLES ---
  bool _isCheckingServer = true; 
  bool _isServerOnline = false;
  bool _usePrototypeMode = false; // Lets you bypass the server if it's down

  // ⚠️ YOUR FLASK SERVER IP ⚠️
  final String serverUrl = 'http://192.168.1.115:5000';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // As soon as the app opens, ping the server!
    _checkServerStatus();
  }

  // --- 🌐 NEW: THE HEALTH CHECK FUNCTION ---
  Future<void> _checkServerStatus() async {
    setState(() {
      _isCheckingServer = true;
      _errorMessage = null;
    });

    try {
      // Ping the base URL of your Flask app, give up after 3 seconds
      final response = await http.get(Uri.parse(serverUrl)).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        setState(() {
          _isServerOnline = true;
          _isCheckingServer = false;
          _usePrototypeMode = false;
        });
      } else {
        setState(() {
          _isServerOnline = false;
          _isCheckingServer = false;
        });
      }
    } catch (e) {
      // If it times out or fails to connect, it falls here
      setState(() {
        _isServerOnline = false;
        _isCheckingServer = false;
      });
    }
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
        });
        
        // Decide which function to run based on status
        if (_usePrototypeMode) {
          _searchLogoMockup();
        } else {
          // You would put your real HTTP upload function here once Docker is done!
          // For now, we will just default to mockup so it doesn't crash.
          _searchLogoMockup(); 
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "Failed to pick image: $e");
    }
  }

  // (Keeping your awesome cinematic mockup function)
  Future<void> _searchLogoMockup() async {
    if (_selectedImage == null) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      setState(() => _loadingText = "Segmenting logos...");
      await Future.delayed(const Duration(milliseconds: 1200));
      setState(() => _loadingText = "Extracting feature vectors...");
      await Future.delayed(const Duration(milliseconds: 1200));
      setState(() => _loadingText = "Searching database...");
      await Future.delayed(const Duration(milliseconds: 1200));

      final fakeResponse = {
        "status": "success",
        "matches": [
          {"brand": "Burger King", "confidence": 98.75, "domain": "Food & Beverage", "logo_url": "https://logo.clearbit.com/burgerking.com"},
          {"brand": "McDonald's", "confidence": 42.10, "domain": "Food & Beverage", "logo_url": "https://logo.clearbit.com/mcdonalds.com"}
        ]
      };

      setState(() {
        _results = fakeResponse['matches'] as List<dynamic>;
        _showSegmentation = true; 
      });
    } catch (e) {
      setState(() => _errorMessage = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- 🚧 NEW: INITIAL STARTUP SCREEN ---
    if (_isCheckingServer) {
      return Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: Colors.greenAccent),
              SizedBox(height: 24),
              Text("Connecting to AI Backend...", 
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    // --- ❌ NEW: SERVER OFFLINE SCREEN ---
    if (!_isServerOnline && !_usePrototypeMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Server Offline')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 80, color: Colors.redAccent),
                const SizedBox(height: 24),
                const Text("Cannot reach the Flask API.", 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Make sure $serverUrl is running and your phone is on the same Wi-Fi.", 
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _checkServerStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry Connection"),
                ),
                TextButton(
                  onPressed: () => setState(() => _usePrototypeMode = true),
                  child: const Text("Bypass & Use Prototype Mode"),
                )
              ],
            ),
          ),
        ),
      );
    }

    // --- ✅ MAIN APP UI ---
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logo Scanner AI', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
        // Status indicator in the top right corner!
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(
                  _usePrototypeMode ? Icons.warning_amber_rounded : Icons.check_circle,
                  color: _usePrototypeMode ? Colors.orange : Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _usePrototypeMode ? "Mock Mode" : "Online",
                  style: TextStyle(
                    color: _usePrototypeMode ? Colors.orange : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: Stack(
        // ... (The rest of your Stack code from earlier remains exactly the same!)
        // Keep your Container, Row with buttons, ListView, and Cinematic Overlay here.
        children: [
          Column(
            children: [
              Container(
                height: 300,
                width: double.infinity,
                color: Colors.black87,
                child: _selectedImage != null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.file(_selectedImage!, fit: BoxFit.contain),
                          if (_showSegmentation)
                            Positioned(
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.greenAccent, width: 3),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)
                                  ]
                                ),
                                child: const Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Text("98%", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, backgroundColor: Colors.black54)),
                                  ),
                                ),
                              ),
                            )
                        ],
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_search, size: 60, color: Colors.white54),
                            SizedBox(height: 16),
                            Text('Upload an image to scan', style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ],
              ),
              const Divider(height: 32),
              Expanded(
                child: _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          var match = _results[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 3,
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  match['logo_url'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                ),
                              ),
                              title: Text(match['brand'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(match['domain']),
                              trailing: Chip(
                                label: Text("${match['confidence']}%"),
                                backgroundColor: index == 0 ? Colors.green[100] : Colors.grey[200],
                                labelStyle: TextStyle(color: index == 0 ? Colors.green[800] : Colors.black87, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
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
