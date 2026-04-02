import 'dart:io';
import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  final File? image;
  final bool showSegmentation;

  const ImagePreview({
    Key? key,
    required this.image,
    required this.showSegmentation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300, 
      width: double.infinity, 
      color: Colors.black87,
      child: image != null
          ? Stack(
              alignment: Alignment.center,
              children: [
                Image.file(image!, fit: BoxFit.contain),
                if (showSegmentation)
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent, width: 3),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)]
                    ),
                    child: const Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Text("98%", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, backgroundColor: Colors.black54)),
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
    );
  }
}
