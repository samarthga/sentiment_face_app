import 'package:flutter/material.dart';
import '../features/face/domain/emotion_state.dart';

/// Stub implementation for non-web platforms
/// Falls back to the placeholder face
class ThreeJsFaceWidget extends StatelessWidget {
  final EmotionState emotion;

  const ThreeJsFaceWidget({super.key, required this.emotion});

  @override
  Widget build(BuildContext context) {
    // Return empty container - will use placeholder on non-web
    return const Center(
      child: Text(
        'Three.js face only available on web.\nUse Unity integration for mobile.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
