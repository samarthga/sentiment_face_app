import 'emotion_state.dart';
import '../../settings/domain/expression_type.dart';

/// Builds prompts for source-specific face generation with topic context.
class ContextualPromptBuilder {
  /// Build a prompt for a specific source.
  static String buildSourcePrompt({
    required EmotionState emotion,
    required String topic,
    required String sourceName,
    required ExpressionType expressionType,
  }) {
    final emotionDesc = _getEmotionDescription(emotion);

    return '''
Passport-style photograph of a person showing $emotionDesc.
- Looking straight at the camera
- Centered face, head and shoulders visible
- Plain light gray or white background
- Even, flat lighting with no harsh shadows
- High resolution, photorealistic quality
- Natural skin texture and details
- Authentic, genuine emotional expression

STYLE: Passport photo, frontal view, neutral background, sharp focus, even lighting.
''';
  }

  /// Get emotion description for the dominant emotion.
  static String _getEmotionDescription(EmotionState emotion) {
    final dominant = emotion.dominantEmotion;
    final intensity = emotion.dominantIntensity;

    String intensityWord;
    if (intensity > 0.7) {
      intensityWord = 'intensely';
    } else if (intensity > 0.5) {
      intensityWord = 'clearly';
    } else if (intensity > 0.3) {
      intensityWord = 'moderately';
    } else {
      intensityWord = 'subtly';
    }

    final emotionDesc = _getEmotionWord(dominant, intensity);
    return '$intensityWord $emotionDesc';
  }

  /// Get the specific emotion word/phrase.
  static String _getEmotionWord(String emotion, double intensity) {
    switch (emotion) {
      case 'happiness':
        return intensity > 0.6
            ? 'joy and excitement, smiling broadly'
            : 'contentment, gentle smile';
      case 'sadness':
        return intensity > 0.6
            ? 'deep sadness, perhaps near tears'
            : 'melancholy, pensive expression';
      case 'anger':
        return intensity > 0.6
            ? 'anger and frustration, furrowed brows'
            : 'irritation, slight frown';
      case 'fear':
        return intensity > 0.6
            ? 'alarm and concern, wide eyes'
            : 'worry and anxiety';
      case 'surprise':
        return intensity > 0.6
            ? 'shock and astonishment, raised eyebrows'
            : 'surprise and curiosity';
      case 'disgust':
        return intensity > 0.6
            ? 'disgust and revulsion, wrinkled nose'
            : 'distaste and disapproval';
      default:
        return 'neutral contemplation';
    }
  }

  /// Build a simpler prompt (for fallback).
  static String buildSimplePrompt({
    required EmotionState emotion,
    required ExpressionType expressionType,
  }) {
    final emotionDesc = _getEmotionDescription(emotion);

    return '''
Passport-style photograph of a person showing $emotionDesc.
Looking straight at the camera, centered face, plain light gray background,
even flat lighting, photorealistic, authentic emotion.
''';
  }
}
