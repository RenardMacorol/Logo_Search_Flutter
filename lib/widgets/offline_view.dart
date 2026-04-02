import 'package:flutter/material.dart';

class OfflineView extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBypass;

  const OfflineView({
    Key? key,
    required this.onRetry,
    required this.onBypass,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              const Text("Cannot reach the Flask API.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry Connection"),
              ),
              TextButton(
                onPressed: onBypass,
                child: const Text("Bypass & Use Prototype Mode"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
