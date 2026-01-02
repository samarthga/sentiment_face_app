import 'package:freezed_annotation/freezed_annotation.dart';

part 'emotion_state.freezed.dart';
part 'emotion_state.g.dart';

/// Represents the complete emotional state derived from sentiment analysis.
/// Values range from 0.0 (absent) to 1.0 (fully expressed).
@freezed
class EmotionState with _$EmotionState {
  const factory EmotionState({
    // Primary emotions (Ekman's basic emotions)
    @Default(0.0) double happiness,
    @Default(0.0) double sadness,
    @Default(0.0) double anger,
    @Default(0.0) double fear,
    @Default(0.0) double surprise,
    @Default(0.0) double disgust,

    // Secondary/complex emotions
    @Default(0.0) double confusion,
    @Default(0.0) double pride,
    @Default(0.0) double loneliness,
    @Default(0.0) double pain,
    @Default(0.0) double contempt,
    @Default(0.0) double anticipation,
    @Default(0.0) double trust,

    // Overall sentiment score (-1.0 to 1.0)
    @Default(0.0) double overallSentiment,

    // Intensity of expression (0.0 to 1.0)
    @Default(0.5) double intensity,

    // Timestamp of this state
    DateTime? timestamp,

    // Source breakdown
    @Default({}) Map<String, double> sourceContributions,
  }) = _EmotionState;

  factory EmotionState.fromJson(Map<String, dynamic> json) =>
      _$EmotionStateFromJson(json);

  const EmotionState._();

  /// Returns the dominant emotion name
  String get dominantEmotion {
    final emotions = {
      'happiness': happiness,
      'sadness': sadness,
      'anger': anger,
      'fear': fear,
      'surprise': surprise,
      'disgust': disgust,
      'confusion': confusion,
      'pride': pride,
      'loneliness': loneliness,
      'pain': pain,
      'contempt': contempt,
    };

    final sorted = emotions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  /// Returns the intensity of the dominant emotion
  double get dominantIntensity {
    final emotions = [
      happiness, sadness, anger, fear, surprise, disgust,
      confusion, pride, loneliness, pain, contempt,
    ];
    return emotions.reduce((a, b) => a > b ? a : b);
  }
}

/// Facial Action Units (FACS) for blend shape control.
/// Based on Ekman's Facial Action Coding System.
@freezed
class FacialActionUnits with _$FacialActionUnits {
  const factory FacialActionUnits({
    // Upper face
    @Default(0.0) double au1InnerBrowRaise,
    @Default(0.0) double au2OuterBrowRaise,
    @Default(0.0) double au4BrowLower,
    @Default(0.0) double au5UpperLidRaise,
    @Default(0.0) double au6CheekRaise,
    @Default(0.0) double au7LidTighten,

    // Lower face
    @Default(0.0) double au9NoseWrinkle,
    @Default(0.0) double au10UpperLipRaise,
    @Default(0.0) double au12LipCornerPull, // smile
    @Default(0.0) double au14Dimpler,
    @Default(0.0) double au15LipCornerDepress, // frown
    @Default(0.0) double au17ChinRaise,
    @Default(0.0) double au20LipStretch,
    @Default(0.0) double au23LipTighten,
    @Default(0.0) double au24LipPress,
    @Default(0.0) double au25LipsPart,
    @Default(0.0) double au26JawDrop,
    @Default(0.0) double au27MouthStretch,

    // Eye movement
    @Default(0.0) double au61EyesLeft,
    @Default(0.0) double au62EyesRight,
    @Default(0.0) double au63EyesUp,
    @Default(0.0) double au64EyesDown,

    // Misc
    @Default(0.0) double au45Blink,
    @Default(0.0) double au46Wink,
  }) = _FacialActionUnits;

  factory FacialActionUnits.fromJson(Map<String, dynamic> json) =>
      _$FacialActionUnitsFromJson(json);
}
