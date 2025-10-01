import 'package:flutter/material.dart';

class VoiceCallScreen extends StatelessWidget {
  const VoiceCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade700,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.call, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text("Voice Call in Progress...",
                style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.call_end),
              label: const Text("End Call"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      ),
    );
  }
}
