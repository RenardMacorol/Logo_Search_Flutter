import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'galaxy_screen.dart';

class HomeScreen extends StatelessWidget {
  // 🟢 IMPORTANTE: Dagdagan ng 'const' dito para hindi mag-error ang main.dart
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0f172a), Color(0xFF1e293b)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or Title
            const Icon(Icons.blur_on, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text(
              "WONKSNET AI",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
            const Text(
              "Visual Intelligence System",
              style: TextStyle(color: Colors.blueGrey, letterSpacing: 1.5),
            ),
            const SizedBox(height: 60),

            // Button 1: Scanner
            _buildMenuButton(
              context,
              "LOGO SCANNER",
              Icons.center_focus_strong,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const SearchScreen()),
              ),
            ),

            const SizedBox(height: 20),

            // Button 2: Market Galaxy
            _buildMenuButton(
              context,
              "MARKET GALAXY",
              Icons.auto_awesome_motion,
              Colors.purpleAccent,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const GalaxyScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.5), width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 20),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
