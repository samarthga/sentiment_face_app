import 'package:flutter/material.dart';

/// Centralized emotion color definitions.
/// Consolidates duplicated color logic from multiple files.
abstract class EmotionColors {
  /// Get the primary color for an emotion.
  static Color getColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happiness':
        return const Color(0xFFFFC107); // Amber
      case 'sadness':
        return const Color(0xFF2196F3); // Blue
      case 'anger':
        return const Color(0xFFF44336); // Red
      case 'fear':
        return const Color(0xFF9C27B0); // Purple
      case 'surprise':
        return const Color(0xFFFF9800); // Orange
      case 'disgust':
        return const Color(0xFF4CAF50); // Green
      case 'confusion':
        return const Color(0xFF009688); // Teal
      case 'pride':
        return const Color(0xFFFFA000); // Amber 700
      case 'loneliness':
        return const Color(0xFF3F51B5); // Indigo
      case 'pain':
        return const Color(0xFFFF5722); // Deep Orange
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Get a gradient for an emotion.
  static LinearGradient getGradient(String emotion) {
    final baseColor = getColor(emotion);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(0.7),
        baseColor,
        baseColor.withOpacity(0.85),
      ],
    );
  }

  /// Get a radial gradient for backgrounds.
  static RadialGradient getRadialGradient(String emotion, {double opacity = 0.3}) {
    final baseColor = getColor(emotion);
    return RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        baseColor.withOpacity(opacity),
        baseColor.withOpacity(opacity * 0.5),
        Colors.transparent,
      ],
    );
  }

  /// Get sentiment color based on value (-1 to 1).
  static Color getSentimentColor(double sentiment) {
    if (sentiment > 0.2) {
      return Colors.green;
    } else if (sentiment < -0.2) {
      return Colors.red;
    }
    return Colors.orange;
  }

  /// Get a lighter version of the emotion color.
  static Color getLightColor(String emotion) {
    return getColor(emotion).withOpacity(0.2);
  }

  /// Get a darker version of the emotion color for shadows.
  static Color getShadowColor(String emotion) {
    return getColor(emotion).withOpacity(0.4);
  }
}
