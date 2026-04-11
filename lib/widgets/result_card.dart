import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/logo_match.dart';

class ResultCard extends StatelessWidget {
  final LogoMatch match;
  final bool isTopMatch;

  const ResultCard({
    Key? key,
    required this.match,
    this.isTopMatch = false,
  }) : super(key: key);

  // Helper para sa kulay base sa stability
  Color _getStatusColor() {
    switch (match.stability) {
      case 'Strong Contender':
        return Colors.green.shade600;
      case 'Ambiguous Match':
        return Colors.orange.shade700;
      case 'Domain Mismatch':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final bool isAmbiguous = match.stability == 'Ambiguous Match';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isTopMatch ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isTopMatch 
            ? BorderSide(color: statusColor.withOpacity(0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thumbnail Section
            _buildThumbnail(),

            const SizedBox(width: 15),

            // 2. Info Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          match.brandName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Match Percentage Badge
                      Text(
                        "${(match.confidence * 100).toStringAsFixed(1)}%",
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Industry Badge
                  Text(
                    match.domain.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3. Stability & Margin Logic
                  Row(
                    children: [
                      // Status Label Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          match.stability.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),

                      // Margin Lead Info (Eto yung pamatay sa defense)
                      if (isTopMatch && match.marginGap > 0)
                        Expanded(
                          child: Text(
                            "GAP: ${match.marginGap.toStringAsFixed(1)}%",
                            style: TextStyle(
                              color: isAmbiguous ? Colors.orange.shade900 : Colors.green.shade900,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Ambiguous Warning Message
                  if (isAmbiguous && isTopMatch)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              "High visual similarity detected with other candidates.",
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 9,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: match.thumbnailBase64 != null && match.thumbnailBase64!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.memory(
                base64Decode(match.thumbnailBase64!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.broken_image, size: 30, color: Colors.grey),
              ),
            )
          : const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
    );
  }
}
