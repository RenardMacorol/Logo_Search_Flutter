import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/logo_match.dart';

class ResultCard extends StatefulWidget {
  final LogoMatch match;
  final bool isTopMatch;

  // 🟢 FIXED: Tinanggal ang hiwalay na forensicBase64 parameter. 
  // Lahat ng data ay manggagaling na sa widget.match
  const ResultCard({
    Key? key,
    required this.match,
    this.isTopMatch = false,
  }) : super(key: key);

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  bool _isExpanded = false;

  Color _getStatusColor() {
    switch (widget.match.stability) {
      case 'Strong Contender':
        return Colors.green.shade400;
      case 'Ambiguous Match':
        return Colors.orange.shade400;
      case 'Domain Mismatch':
        return Colors.redAccent;
      default:
        return Colors.blueAccent;
    }
  }

  // Helper function para linisin ang Base64 string bago i-decode
  String _cleanBase64(String b64) {
    if (b64.contains(',')) return b64.split(',').last;
    return b64;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    
    // 🟢 SYNCED WITH API: Chine-check ang forensicBase64 sa loob ng match object
    final hasForensic = widget.match.forensicBase64 != null && 
                         widget.match.forensicBase64!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (hasForensic) {
          setState(() => _isExpanded = !_isExpanded);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(15),
          border: widget.isTopMatch
              ? Border.all(color: statusColor.withOpacity(0.6), width: 1.5)
              : Border.all(color: Colors.white.withOpacity(0.05), width: 1),
          boxShadow: [
            if (widget.isTopMatch)
              BoxShadow(
                color: statusColor.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              )
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThumbnail(),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(statusColor),
                        const SizedBox(height: 4),
                        _buildSubHeader(),
                        const SizedBox(height: 10),
                        _buildBadges(statusColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 🟢 DYNAMIC FORENSIC SECTION
            if (hasForensic) ...[
              if (!_isExpanded) _buildExpandPrompt(statusColor),
              if (_isExpanded) _buildForensicPanel(statusColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.match.brandName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 🟢 PRESERVED LOGIC: Ginagamit ang weight fix na ginawa mo sa model
        Text(
          "${(widget.match.confidence * 100).toStringAsFixed(1)}%",
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSubHeader() {
    return Text(
      widget.match.domain.toUpperCase(),
      style: const TextStyle(
        color: Colors.white38, 
        fontSize: 10, 
        letterSpacing: 1.1, 
        fontWeight: FontWeight.bold
      ),
    );
  }

  Widget _buildBadges(Color statusColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _badge(widget.match.stability.toUpperCase(), statusColor),
        if (widget.match.marginGap > 0)
          _badge("GAP: ${widget.match.marginGap.toStringAsFixed(1)}%", Colors.blueGrey.shade300),
      ],
    );
  }

  Widget _buildExpandPrompt(Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.expand_more, color: statusColor.withOpacity(0.5), size: 14),
          const SizedBox(width: 4),
          Text(
            "VIEW FORENSIC EVIDENCE",
            style: TextStyle(
              color: statusColor.withOpacity(0.5),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForensicPanel(Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
        border: Border(top: BorderSide(color: statusColor.withOpacity(0.2))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.greenAccent, size: 14),
              const SizedBox(width: 6),
              // 🟢 ORB ADDITION: Pinapakita ang geometric match score
              Text(
                "ORB SIMILARITY: ${widget.match.orbSimilarity.toStringAsFixed(1)}%",
                style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(_cleanBase64(widget.match.forensicBase64!)),
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white10),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Feature-point mapping confirmed via Forensic Cross-Validation",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 8, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => setState(() => _isExpanded = false),
            child: const Text("CLOSE EVIDENCE", style: TextStyle(color: Colors.redAccent, fontSize: 9)),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 70, height: 70,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: widget.match.thumbnailBase64 != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.memory(
                base64Decode(_cleanBase64(widget.match.thumbnailBase64!)),
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white10),
              ),
            )
          : const Icon(Icons.image, color: Colors.white10),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
