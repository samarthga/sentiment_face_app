import 'emotion_state.dart';

/// Maps EmotionState to FacialActionUnits for Unity blend shapes.
class EmotionMapper {
  /// Converts an emotion state to facial action units for rendering.
  static FacialActionUnits toActionUnits(EmotionState emotion) {
    // Start with neutral face
    var au1 = 0.0; // Inner brow raise
    var au2 = 0.0; // Outer brow raise
    var au4 = 0.0; // Brow lower
    var au5 = 0.0; // Upper lid raise
    var au6 = 0.0; // Cheek raise
    var au7 = 0.0; // Lid tighten
    var au9 = 0.0; // Nose wrinkle
    var au10 = 0.0; // Upper lip raise
    var au12 = 0.0; // Lip corner pull (smile)
    var au15 = 0.0; // Lip corner depress (frown)
    var au17 = 0.0; // Chin raise
    var au20 = 0.0; // Lip stretch
    var au25 = 0.0; // Lips part
    var au26 = 0.0; // Jaw drop
    var au27 = 0.0; // Mouth stretch

    final intensity = emotion.intensity;

    // HAPPINESS: Duchenne smile
    au12 += emotion.happiness * 0.9 * intensity; // Smile
    au6 += emotion.happiness * 0.7 * intensity; // Cheek raise (genuine smile)
    au25 += emotion.happiness * 0.3 * intensity; // Slight lip part

    // SADNESS: Oblique eyebrows, frown
    au1 += emotion.sadness * 0.8 * intensity; // Inner brow raise
    au4 += emotion.sadness * 0.4 * intensity; // Brow lower (together = sad brow)
    au15 += emotion.sadness * 0.6 * intensity; // Lip corner depress
    au17 += emotion.sadness * 0.3 * intensity; // Chin raise (trembling chin)

    // ANGER: Lowered brows, tight mouth
    au4 += emotion.anger * 0.9 * intensity; // Brow lower
    au7 += emotion.anger * 0.6 * intensity; // Lid tighten
    au9 += emotion.anger * 0.4 * intensity; // Nose wrinkle
    au10 += emotion.anger * 0.3 * intensity; // Upper lip raise

    // FEAR: Raised brows, wide eyes
    au1 += emotion.fear * 0.7 * intensity; // Inner brow raise
    au2 += emotion.fear * 0.7 * intensity; // Outer brow raise
    au5 += emotion.fear * 0.8 * intensity; // Upper lid raise
    au20 += emotion.fear * 0.5 * intensity; // Lip stretch
    au26 += emotion.fear * 0.4 * intensity; // Jaw drop

    // SURPRISE: Raised brows, open mouth
    au1 += emotion.surprise * 0.8 * intensity;
    au2 += emotion.surprise * 0.8 * intensity;
    au5 += emotion.surprise * 0.6 * intensity;
    au26 += emotion.surprise * 0.7 * intensity;

    // DISGUST: Nose wrinkle, raised upper lip
    au9 += emotion.disgust * 0.9 * intensity;
    au10 += emotion.disgust * 0.8 * intensity;
    au4 += emotion.disgust * 0.3 * intensity;

    // CONFUSION: Asymmetric brow, squint
    au4 += emotion.confusion * 0.5 * intensity;
    au7 += emotion.confusion * 0.4 * intensity;

    // PRIDE: Head tilt up, subtle smile
    au12 += emotion.pride * 0.3 * intensity;
    au6 += emotion.pride * 0.2 * intensity;

    // LONELINESS: Subtle sadness
    au1 += emotion.loneliness * 0.4 * intensity;
    au15 += emotion.loneliness * 0.4 * intensity;

    // PAIN: Brow lower, eye squeeze, mouth tension
    au4 += emotion.pain * 0.7 * intensity;
    au6 += emotion.pain * 0.5 * intensity;
    au7 += emotion.pain * 0.6 * intensity;
    au9 += emotion.pain * 0.4 * intensity;
    au27 += emotion.pain * 0.3 * intensity;

    // CONTEMPT: Asymmetric lip corner
    au12 += emotion.contempt * 0.3 * intensity; // One-sided would need asymmetry flag

    // Clamp all values to 0.0-1.0
    double clamp(double v) => v.clamp(0.0, 1.0);

    return FacialActionUnits(
      au1InnerBrowRaise: clamp(au1),
      au2OuterBrowRaise: clamp(au2),
      au4BrowLower: clamp(au4),
      au5UpperLidRaise: clamp(au5),
      au6CheekRaise: clamp(au6),
      au7LidTighten: clamp(au7),
      au9NoseWrinkle: clamp(au9),
      au10UpperLipRaise: clamp(au10),
      au12LipCornerPull: clamp(au12),
      au15LipCornerDepress: clamp(au15),
      au17ChinRaise: clamp(au17),
      au20LipStretch: clamp(au20),
      au25LipsPart: clamp(au25),
      au26JawDrop: clamp(au26),
      au27MouthStretch: clamp(au27),
    );
  }

  /// Interpolates between two emotion states for smooth transitions.
  static EmotionState lerp(EmotionState a, EmotionState b, double t) {
    double lerpDouble(double x, double y) => x + (y - x) * t;

    return EmotionState(
      happiness: lerpDouble(a.happiness, b.happiness),
      sadness: lerpDouble(a.sadness, b.sadness),
      anger: lerpDouble(a.anger, b.anger),
      fear: lerpDouble(a.fear, b.fear),
      surprise: lerpDouble(a.surprise, b.surprise),
      disgust: lerpDouble(a.disgust, b.disgust),
      confusion: lerpDouble(a.confusion, b.confusion),
      pride: lerpDouble(a.pride, b.pride),
      loneliness: lerpDouble(a.loneliness, b.loneliness),
      pain: lerpDouble(a.pain, b.pain),
      contempt: lerpDouble(a.contempt, b.contempt),
      anticipation: lerpDouble(a.anticipation, b.anticipation),
      trust: lerpDouble(a.trust, b.trust),
      overallSentiment: lerpDouble(a.overallSentiment, b.overallSentiment),
      intensity: lerpDouble(a.intensity, b.intensity),
      timestamp: b.timestamp,
      sourceContributions: b.sourceContributions,
    );
  }
}
