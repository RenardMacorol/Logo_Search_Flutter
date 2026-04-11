import 'package:flutter/material.dart';
import 'dart:math';
import '../models/logo_match.dart';

class LatentMapDialog extends StatelessWidget {
  final dynamic queryPoint; 
  final List<LogoMatch> matches;

  const LatentMapDialog({Key? key, required this.queryPoint, required this.matches}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<double> coords = [0.5, 0.5];
    try {
      if (queryPoint is List) {
        coords = [double.parse(queryPoint[0].toString()), double.parse(queryPoint[1].toString())];
      } else if (queryPoint is Map) {
        coords = [double.parse((queryPoint['x'] ?? 0.5).toString()), double.parse((queryPoint['y'] ?? 0.5).toString())];
      }
    } catch (e) { coords = [0.5, 0.5]; }

    return AlertDialog(
      backgroundColor: const Color(0xFF161625),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
      title: Row(children: const [
        Icon(Icons.bubble_chart, color: Colors.blueAccent),
        SizedBox(width: 10),
        Text("LATENT PROJECTION", style: TextStyle(color: Colors.white, fontSize: 14))
      ]),
      content: SizedBox(
        width: 300, height: 300,
        child: Container(
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
          child: CustomPaint(painter: LatentPainter(queryPoint: coords, matches: matches), size: Size.infinite),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))],
    );
  }
}

class LatentPainter extends CustomPainter {
  final List<double> queryPoint;
  final List<LogoMatch> matches;
  LatentPainter({required this.queryPoint, required this.matches});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rand = Random(42);
    
    // Background Points
    paint.color = Colors.white10;
    for(int i=0; i<50; i++) canvas.drawCircle(Offset(rand.nextDouble()*size.width, rand.nextDouble()*size.height), 1, paint);

    // Matches (Green)
    paint.color = Colors.greenAccent;
    for(var m in matches) {
      double ox = (queryPoint[0] + (rand.nextDouble()-0.5)*0.2) * size.width;
      double oy = (queryPoint[1] + (rand.nextDouble()-0.5)*0.2) * size.height;
      canvas.drawCircle(Offset(ox, oy), 3, paint);
    }

    // Query (Red Glow)
    paint.color = Colors.redAccent;
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(queryPoint[0]*size.width, queryPoint[1]*size.height), 6, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}
