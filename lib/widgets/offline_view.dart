import 'package:flutter/material.dart';

class OfflineView extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBypass;
  // Dagdagan natin nito para alam ng user kung saang IP siya kumokonekta
  final String serverAddress = "192.168.1.106:5000"; 

  const OfflineView({
    Key? key,
    required this.onRetry,
    required this.onBypass,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Connection Error'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 100, color: Colors.orangeAccent),
              const SizedBox(height: 24),
              const Text(
                "Backend Unreachable",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Make sure your Flask server is running on\n$serverAddress",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 40),
              
              // PRIMARY ACTION
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text("RETRY CONNECTION", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // SECONDARY ACTION
              TextButton(
                onPressed: onBypass,
                style: TextButton.styleFrom(foregroundColor: Colors.orange[800]),
                child: const Text("Proceed with Mock/Prototype Mode"),
              ),
              
              const Spacer(),
              
              // ARCH LINUX TIPS (Optional but cool!)
              Text(
                "Tip: Check 'ip addr' and use --host=0.0.0.0",
                style: TextStyle(color: Colors.grey[400], fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
