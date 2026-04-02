import 'package:flutter/material.dart';
import '../models/logo_match.dart';

class ResultCard extends StatelessWidget {
  final LogoMatch match;
  final bool isTopMatch;

  const ResultCard({
    Key? key,
    required this.match,
    required this.isTopMatch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            match.logoUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => 
              const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          ),
        ),
        title: Text(match.brand, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(match.domain),
        trailing: Chip(
          label: Text("${match.confidence}%"),
          backgroundColor: isTopMatch ? Colors.green[100] : Colors.grey[200],
          labelStyle: TextStyle(
            color: isTopMatch ? Colors.green[800] : Colors.black87,
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }
}
