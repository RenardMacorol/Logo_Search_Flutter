import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../services/api_service.dart';

class GalaxyScreen extends StatefulWidget {
  const GalaxyScreen({Key? key}) : super(key: key);

  @override
  State<GalaxyScreen> createState() => _GalaxyScreenState();
}

class _GalaxyScreenState extends State<GalaxyScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _allPoints = [];
  List<dynamic> _filteredPoints = [];
  bool _isLoading = true;
  
  // States para sa Filters
  String _selectedIndustry = 'All';
  String _selectedScope = 'BOTH';
  
  // Selection States
  dynamic _selectedPoint;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getGalaxyPoints(scope: _selectedScope);
      setState(() {
        _allPoints = data;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _applyFilters() {
    setState(() {
      if (_selectedIndustry == 'All') {
        _filteredPoints = _allPoints;
      } else {
        _filteredPoints = _allPoints.where((p) {
          String domain = (p['metadata']['industry_domain'] ?? '').toString().toLowerCase();
          return domain.contains(_selectedIndustry.toLowerCase());
        }).toList();
      }
      _selectedPoint = null; // Reset selection pag nag-filter
    });
  }

  void _handleTap(TapUpDetails details, Size size) {
    double minDistance = 25.0; // Sensitibidad ng touch
    dynamic closest;

    for (var p in _filteredPoints) {
      double dx = p['x'] * size.width;
      double dy = p['y'] * size.height;
      double dist = sqrt(pow(details.localPosition.dx - dx, 2) + pow(details.localPosition.dy - dy, 2));
      
      if (dist < minDistance) {
        minDistance = dist;
        closest = p;
      }
    }

    setState(() {
      _selectedPoint = closest;
      _tapPosition = details.localPosition;
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Stack(
        children: [
          // 🌌 GALAXY ENGINE
          if (!_isLoading)
            GestureDetector(
              onTapUp: (d) => _handleTap(d, MediaQuery.of(context).size),
              child: InteractiveViewer(
                maxScale: 20.0,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CustomPaint(
                      painter: GalaxyPainter(
                        points: _filteredPoints,
                        selectedPoint: _selectedPoint,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),

          // 🏷️ TOP UI: FILTER BY INDUSTRY (Based on image_9a4618.png)
          Positioned(
            top: 15,
            left: 70,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("FILTER BY INDUSTRY", 
                  style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildIndustryChip("All", Colors.blueGrey),
                      _buildIndustryChip("Accessories", const Color(0xFFf87171)),
                      _buildIndustryChip("Clothes", const Color(0xFF60a5fa)),
                      _buildIndustryChip("Cosmetic", const Color(0xFFf472b6)),
                      _buildIndustryChip("Electronic", const Color(0xFFfbbf24)),
                      _buildIndustryChip("Food", const Color(0xFFef4444)),
                      _buildIndustryChip("Institution", const Color(0xFF818cf8)),
                      _buildIndustryChip("Leisure", const Color(0xFF34d399)),
                      _buildIndustryChip("Medical", const Color(0xFFfb7185)),
                      _buildIndustryChip("Transportation", const Color(0xFFfb923c)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 🎛️ BOTTOM UI: FOCUS BUTTONS (Based on image_9a4620.png)
          Positioned(
            bottom: 20,
            right: 20,
            child: Row(
              children: [
                _buildFocusButton("Focus PH", "PH", const Color(0xFF312e81)),
                const SizedBox(width: 10),
                _buildFocusButton("Focus Global", "GLOBAL", const Color(0xFF064e3b)),
                const SizedBox(width: 10),
                _buildFocusButton("Reset All", "BOTH", const Color(0xFF334155)),
              ],
            ),
          ),

          // 📍 POPUP INFO (Based on image_9a45f9.png)
          if (_selectedPoint != null && _tapPosition != null)
            Positioned(
              left: _tapPosition!.dx > MediaQuery.of(context).size.width - 150 ? _tapPosition!.dx - 160 : _tapPosition!.dx + 10,
              top: _tapPosition!.dy > MediaQuery.of(context).size.height - 100 ? _tapPosition!.dy - 100 : _tapPosition!.dy + 10,
              child: Container(
                width: 150,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1e293b).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 10, height: 10, color: _getVividColor((_selectedPoint['metadata']['industry_domain'] ?? '').toString())),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_selectedPoint['metadata']['brand_name'] ?? 'N/A', 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    Text("Industry: ${_selectedPoint['metadata']['industry_domain']}", style: const TextStyle(color: Colors.white70, fontSize: 9)),
                    Text("Scope: ${_selectedPoint['metadata']['origin'] ?? 'GLOBAL'}", style: const TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
          
          // Back Button
          Positioned(top: 20, left: 20, child: CircleAvatar(backgroundColor: Colors.black45, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)))),
        ],
      ),
    );
  }

  Widget _buildIndustryChip(String label, Color color) {
    bool isSel = _selectedIndustry == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndustry = label);
        _applyFilters();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? color.withOpacity(0.2) : Colors.black26,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? color : Colors.white10),
        ),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSel ? Colors.white : Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusButton(String label, String scope, Color color) {
    bool isSel = _selectedScope == scope;
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedScope = scope);
        _loadData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

// 🔵 UPDATED PAINTER WITH VIVID ORANGE TRANSPORTATION
class GalaxyPainter extends CustomPainter {
  final List<dynamic> points;
  final dynamic selectedPoint;
  GalaxyPainter({required this.points, this.selectedPoint});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (var p in points) {
      String domain = (p['metadata']['industry_domain'] ?? 'General').toString().toLowerCase().trim();
      paint.color = _getVividColor(domain).withOpacity(0.7);
      
      double dx = p['x'] * size.width;
      double dy = p['y'] * size.height;

      if (selectedPoint == p) {
        paint.color = Colors.white;
        canvas.drawCircle(Offset(dx, dy), 5, paint);
      } else {
        canvas.drawRect(Rect.fromLTWH(dx, dy, 2.2, 2.2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(GalaxyPainter oldDelegate) => true;
}

// Helper Color Function - Consistent sa Chips at Painter
Color _getVividColor(String d) {
  d = d.toLowerCase();
  if (d.contains('transport')) return const Color(0xFFfb923c); // Orange
  if (d.contains('food')) return const Color(0xFFef4444);        // Red
  if (d.contains('access')) return const Color(0xFFf87171);      // Pink/Red
  if (d.contains('cloth')) return const Color(0xFF60a5fa);       // Blue
  if (d.contains('elect')) return const Color(0xFFfbbf24);       // Amber
  if (d.contains('cosmetic')) return const Color(0xFFf472b6);    // Pink
  if (d.contains('inst')) return const Color(0xFF818cf8);        // Indigo
  if (d.contains('leis')) return const Color(0xFF34d399);        // Green
  if (d.contains('medic')) return const Color(0xFFfb7185);       // Rose
  return const Color(0xFF94a3b8);                                // Slate
}
