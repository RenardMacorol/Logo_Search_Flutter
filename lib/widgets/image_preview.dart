import 'dart:io';
import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  final File? image;
  final bool showSegmentation;
  // Pwede nating dagdagan ng maskData para sa heatmap overlay
  final String? maskBase64; 

  const ImagePreview({
    Key? key, 
    this.image, 
    required this.showSegmentation,
    this.maskBase64,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: image == null
          ? const Center(child: Text("No logo selected"))
          : Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(image!, fit: BoxFit.contain),
                ),
                // Futuristic Overlay pag "Analyzing" or "Done"
                if (showSegmentation)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.greenAccent, width: 3),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
