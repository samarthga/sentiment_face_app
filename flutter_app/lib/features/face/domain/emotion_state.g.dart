// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotion_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EmotionStateImpl _$$EmotionStateImplFromJson(Map<String, dynamic> json) =>
    _$EmotionStateImpl(
      happiness: (json['happiness'] as num?)?.toDouble() ?? 0.0,
      sadness: (json['sadness'] as num?)?.toDouble() ?? 0.0,
      anger: (json['anger'] as num?)?.toDouble() ?? 0.0,
      fear: (json['fear'] as num?)?.toDouble() ?? 0.0,
      surprise: (json['surprise'] as num?)?.toDouble() ?? 0.0,
      disgust: (json['disgust'] as num?)?.toDouble() ?? 0.0,
      confusion: (json['confusion'] as num?)?.toDouble() ?? 0.0,
      pride: (json['pride'] as num?)?.toDouble() ?? 0.0,
      loneliness: (json['loneliness'] as num?)?.toDouble() ?? 0.0,
      pain: (json['pain'] as num?)?.toDouble() ?? 0.0,
      contempt: (json['contempt'] as num?)?.toDouble() ?? 0.0,
      anticipation: (json['anticipation'] as num?)?.toDouble() ?? 0.0,
      trust: (json['trust'] as num?)?.toDouble() ?? 0.0,
      overallSentiment: (json['overallSentiment'] as num?)?.toDouble() ?? 0.0,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.5,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      sourceContributions:
          (json['sourceContributions'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toDouble()),
              ) ??
              const {},
    );

Map<String, dynamic> _$$EmotionStateImplToJson(_$EmotionStateImpl instance) =>
    <String, dynamic>{
      'happiness': instance.happiness,
      'sadness': instance.sadness,
      'anger': instance.anger,
      'fear': instance.fear,
      'surprise': instance.surprise,
      'disgust': instance.disgust,
      'confusion': instance.confusion,
      'pride': instance.pride,
      'loneliness': instance.loneliness,
      'pain': instance.pain,
      'contempt': instance.contempt,
      'anticipation': instance.anticipation,
      'trust': instance.trust,
      'overallSentiment': instance.overallSentiment,
      'intensity': instance.intensity,
      'timestamp': instance.timestamp?.toIso8601String(),
      'sourceContributions': instance.sourceContributions,
    };

_$FacialActionUnitsImpl _$$FacialActionUnitsImplFromJson(
        Map<String, dynamic> json) =>
    _$FacialActionUnitsImpl(
      au1InnerBrowRaise: (json['au1InnerBrowRaise'] as num?)?.toDouble() ?? 0.0,
      au2OuterBrowRaise: (json['au2OuterBrowRaise'] as num?)?.toDouble() ?? 0.0,
      au4BrowLower: (json['au4BrowLower'] as num?)?.toDouble() ?? 0.0,
      au5UpperLidRaise: (json['au5UpperLidRaise'] as num?)?.toDouble() ?? 0.0,
      au6CheekRaise: (json['au6CheekRaise'] as num?)?.toDouble() ?? 0.0,
      au7LidTighten: (json['au7LidTighten'] as num?)?.toDouble() ?? 0.0,
      au9NoseWrinkle: (json['au9NoseWrinkle'] as num?)?.toDouble() ?? 0.0,
      au10UpperLipRaise: (json['au10UpperLipRaise'] as num?)?.toDouble() ?? 0.0,
      au12LipCornerPull: (json['au12LipCornerPull'] as num?)?.toDouble() ?? 0.0,
      au14Dimpler: (json['au14Dimpler'] as num?)?.toDouble() ?? 0.0,
      au15LipCornerDepress:
          (json['au15LipCornerDepress'] as num?)?.toDouble() ?? 0.0,
      au17ChinRaise: (json['au17ChinRaise'] as num?)?.toDouble() ?? 0.0,
      au20LipStretch: (json['au20LipStretch'] as num?)?.toDouble() ?? 0.0,
      au23LipTighten: (json['au23LipTighten'] as num?)?.toDouble() ?? 0.0,
      au24LipPress: (json['au24LipPress'] as num?)?.toDouble() ?? 0.0,
      au25LipsPart: (json['au25LipsPart'] as num?)?.toDouble() ?? 0.0,
      au26JawDrop: (json['au26JawDrop'] as num?)?.toDouble() ?? 0.0,
      au27MouthStretch: (json['au27MouthStretch'] as num?)?.toDouble() ?? 0.0,
      au61EyesLeft: (json['au61EyesLeft'] as num?)?.toDouble() ?? 0.0,
      au62EyesRight: (json['au62EyesRight'] as num?)?.toDouble() ?? 0.0,
      au63EyesUp: (json['au63EyesUp'] as num?)?.toDouble() ?? 0.0,
      au64EyesDown: (json['au64EyesDown'] as num?)?.toDouble() ?? 0.0,
      au45Blink: (json['au45Blink'] as num?)?.toDouble() ?? 0.0,
      au46Wink: (json['au46Wink'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$FacialActionUnitsImplToJson(
        _$FacialActionUnitsImpl instance) =>
    <String, dynamic>{
      'au1InnerBrowRaise': instance.au1InnerBrowRaise,
      'au2OuterBrowRaise': instance.au2OuterBrowRaise,
      'au4BrowLower': instance.au4BrowLower,
      'au5UpperLidRaise': instance.au5UpperLidRaise,
      'au6CheekRaise': instance.au6CheekRaise,
      'au7LidTighten': instance.au7LidTighten,
      'au9NoseWrinkle': instance.au9NoseWrinkle,
      'au10UpperLipRaise': instance.au10UpperLipRaise,
      'au12LipCornerPull': instance.au12LipCornerPull,
      'au14Dimpler': instance.au14Dimpler,
      'au15LipCornerDepress': instance.au15LipCornerDepress,
      'au17ChinRaise': instance.au17ChinRaise,
      'au20LipStretch': instance.au20LipStretch,
      'au23LipTighten': instance.au23LipTighten,
      'au24LipPress': instance.au24LipPress,
      'au25LipsPart': instance.au25LipsPart,
      'au26JawDrop': instance.au26JawDrop,
      'au27MouthStretch': instance.au27MouthStretch,
      'au61EyesLeft': instance.au61EyesLeft,
      'au62EyesRight': instance.au62EyesRight,
      'au63EyesUp': instance.au63EyesUp,
      'au64EyesDown': instance.au64EyesDown,
      'au45Blink': instance.au45Blink,
      'au46Wink': instance.au46Wink,
    };
