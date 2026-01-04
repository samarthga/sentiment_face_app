import 'emotion_state.dart';

/// Builds descriptive prompts for Gemini image generation based on emotion state.
class EmotionPromptBuilder {
  /// Base prompt template for hyper-realistic face generation.
  static const String _basePrompt = '''
Generate a hyper-realistic photograph of a human face showing the following emotional expression.
The image should be:
- A close-up portrait photograph
- Studio lighting with soft shadows
- Neutral background (gradient gray)
- High resolution, photorealistic quality
- Natural skin texture and details
- The person should be looking directly at camera
''';

  /// Build a complete prompt from emotion state.
  static String buildPrompt(EmotionState emotion) {
    final emotionDescription = _buildEmotionDescription(emotion);
    final facialFeatures = _buildFacialFeatures(emotion);

    return '''
$_basePrompt

EMOTIONAL EXPRESSION:
$emotionDescription

FACIAL FEATURES TO EMPHASIZE:
$facialFeatures

Style: Professional portrait photography, 85mm lens, shallow depth of field, catchlights in eyes.
''';
  }

  /// Build a description of the emotional state.
  static String _buildEmotionDescription(EmotionState emotion) {
    final parts = <String>[];

    // Get dominant emotion
    final dominant = emotion.dominantEmotion;
    final dominantIntensity = emotion.dominantIntensity;

    // Describe intensity level
    String intensityWord;
    if (dominantIntensity > 0.8) {
      intensityWord = 'intensely';
    } else if (dominantIntensity > 0.6) {
      intensityWord = 'clearly';
    } else if (dominantIntensity > 0.4) {
      intensityWord = 'moderately';
    } else if (dominantIntensity > 0.2) {
      intensityWord = 'subtly';
    } else {
      intensityWord = 'barely';
    }

    // Primary emotion description
    final primaryDesc = _getEmotionDescription(dominant, dominantIntensity);
    parts.add('The face shows $intensityWord $primaryDesc.');

    // Add secondary emotions if significant
    final emotions = {
      'happiness': emotion.happiness,
      'sadness': emotion.sadness,
      'anger': emotion.anger,
      'fear': emotion.fear,
      'surprise': emotion.surprise,
      'disgust': emotion.disgust,
    };

    // Find secondary emotions (above 0.2 and not dominant)
    final secondary = emotions.entries
        .where((e) => e.key != dominant && e.value > 0.2)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (secondary.isNotEmpty) {
      final secondaryDesc = secondary
          .take(2)
          .map((e) => _getEmotionDescription(e.key, e.value))
          .join(' and ');
      parts.add('There are also hints of $secondaryDesc.');
    }

    // Overall sentiment
    if (emotion.overallSentiment > 0.3) {
      parts.add('The overall expression conveys positivity and warmth.');
    } else if (emotion.overallSentiment < -0.3) {
      parts.add('The overall expression conveys negativity or distress.');
    } else {
      parts.add('The overall expression is relatively neutral but nuanced.');
    }

    return parts.join('\n');
  }

  /// Get a natural language description for an emotion.
  static String _getEmotionDescription(String emotion, double intensity) {
    switch (emotion) {
      case 'happiness':
        if (intensity > 0.7) {
          return 'joy and genuine happiness with a warm, authentic smile';
        } else if (intensity > 0.4) {
          return 'contentment and mild happiness with a gentle smile';
        } else {
          return 'a hint of amusement or slight pleasure';
        }

      case 'sadness':
        if (intensity > 0.7) {
          return 'deep sadness and sorrow, perhaps on the verge of tears';
        } else if (intensity > 0.4) {
          return 'melancholy and wistfulness';
        } else {
          return 'a subtle sadness or pensiveness';
        }

      case 'anger':
        if (intensity > 0.7) {
          return 'intense anger and frustration with furrowed brows';
        } else if (intensity > 0.4) {
          return 'irritation and displeasure';
        } else {
          return 'mild annoyance or slight frustration';
        }

      case 'fear':
        if (intensity > 0.7) {
          return 'terror and alarm with wide eyes';
        } else if (intensity > 0.4) {
          return 'anxiety and worry';
        } else {
          return 'slight unease or apprehension';
        }

      case 'surprise':
        if (intensity > 0.7) {
          return 'shock and astonishment with raised eyebrows and open mouth';
        } else if (intensity > 0.4) {
          return 'surprise and wonder';
        } else {
          return 'mild curiosity or slight amazement';
        }

      case 'disgust':
        if (intensity > 0.7) {
          return 'strong disgust and revulsion with wrinkled nose';
        } else if (intensity > 0.4) {
          return 'distaste and aversion';
        } else {
          return 'slight displeasure or mild disapproval';
        }

      default:
        return 'a neutral expression';
    }
  }

  /// Build specific facial feature instructions.
  static String _buildFacialFeatures(EmotionState emotion) {
    final features = <String>[];

    // Eyes
    if (emotion.happiness > 0.5) {
      features.add('- Eyes: Slightly squinted with crow\'s feet, bright and engaged');
    } else if (emotion.sadness > 0.5) {
      features.add('- Eyes: Slightly downcast, perhaps glistening, heavy eyelids');
    } else if (emotion.anger > 0.5) {
      features.add('- Eyes: Narrowed and intense, piercing gaze');
    } else if (emotion.fear > 0.5) {
      features.add('- Eyes: Wide open, showing more white, alert and tense');
    } else if (emotion.surprise > 0.5) {
      features.add('- Eyes: Wide open with raised upper eyelids, attentive');
    } else if (emotion.disgust > 0.5) {
      features.add('- Eyes: Slightly narrowed with tension around the lids');
    } else {
      features.add('- Eyes: Relaxed, natural gaze with neutral expression');
    }

    // Eyebrows
    if (emotion.anger > 0.4) {
      features.add('- Eyebrows: Lowered and drawn together, creating furrows');
    } else if (emotion.sadness > 0.4) {
      features.add('- Eyebrows: Inner corners raised, creating a worried look');
    } else if (emotion.surprise > 0.4 || emotion.fear > 0.4) {
      features.add('- Eyebrows: Raised high, arched upward');
    } else if (emotion.happiness > 0.4) {
      features.add('- Eyebrows: Slightly raised, open and relaxed');
    } else {
      features.add('- Eyebrows: Neutral position, relaxed');
    }

    // Mouth
    if (emotion.happiness > 0.6) {
      features.add('- Mouth: Genuine Duchenne smile, corners pulled up, teeth may show');
    } else if (emotion.happiness > 0.3) {
      features.add('- Mouth: Soft smile, lips gently curved upward');
    } else if (emotion.sadness > 0.5) {
      features.add('- Mouth: Corners turned down, lips may tremble slightly');
    } else if (emotion.anger > 0.5) {
      features.add('- Mouth: Lips pressed together firmly, jaw clenched');
    } else if (emotion.fear > 0.5) {
      features.add('- Mouth: Slightly open, lips stretched horizontally');
    } else if (emotion.surprise > 0.5) {
      features.add('- Mouth: Open in an "O" shape, jaw dropped');
    } else if (emotion.disgust > 0.5) {
      features.add('- Mouth: Upper lip raised, nose wrinkled');
    } else {
      features.add('- Mouth: Relaxed, lips closed naturally');
    }

    // Nose
    if (emotion.disgust > 0.4) {
      features.add('- Nose: Wrinkled, nostrils may flare');
    } else if (emotion.anger > 0.5) {
      features.add('- Nose: Nostrils slightly flared');
    }

    // Overall tension
    final tension = emotion.intensity;
    if (tension > 0.7) {
      features.add('- Muscle tension: High, visible tension in facial muscles');
    } else if (tension > 0.4) {
      features.add('- Muscle tension: Moderate, some facial engagement');
    } else {
      features.add('- Muscle tension: Low, relaxed facial muscles');
    }

    return features.join('\n');
  }

  /// Build a shorter prompt for faster generation.
  static String buildShortPrompt(EmotionState emotion) {
    final dominant = emotion.dominantEmotion;
    final intensity = emotion.dominantIntensity;

    String emotionWord;
    switch (dominant) {
      case 'happiness':
        emotionWord = intensity > 0.6 ? 'joyful, smiling' : 'content, slight smile';
        break;
      case 'sadness':
        emotionWord = intensity > 0.6 ? 'sad, sorrowful' : 'melancholic, pensive';
        break;
      case 'anger':
        emotionWord = intensity > 0.6 ? 'angry, furious' : 'irritated, annoyed';
        break;
      case 'fear':
        emotionWord = intensity > 0.6 ? 'terrified, alarmed' : 'anxious, worried';
        break;
      case 'surprise':
        emotionWord = intensity > 0.6 ? 'shocked, astonished' : 'surprised, curious';
        break;
      case 'disgust':
        emotionWord = intensity > 0.6 ? 'disgusted, revolted' : 'displeased, averse';
        break;
      default:
        emotionWord = 'neutral';
    }

    return '''
Hyper-realistic portrait photograph of a person with a $emotionWord expression.
Close-up face, studio lighting, gray background, photorealistic, 85mm lens.
Natural skin, detailed eyes, authentic emotion, looking at camera.
''';
  }
}
