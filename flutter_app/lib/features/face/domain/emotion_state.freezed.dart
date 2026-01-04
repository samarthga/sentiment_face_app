// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'emotion_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EmotionState _$EmotionStateFromJson(Map<String, dynamic> json) {
  return _EmotionState.fromJson(json);
}

/// @nodoc
mixin _$EmotionState {
// Primary emotions (Ekman's basic emotions)
  double get happiness => throw _privateConstructorUsedError;
  double get sadness => throw _privateConstructorUsedError;
  double get anger => throw _privateConstructorUsedError;
  double get fear => throw _privateConstructorUsedError;
  double get surprise => throw _privateConstructorUsedError;
  double get disgust =>
      throw _privateConstructorUsedError; // Secondary/complex emotions
  double get confusion => throw _privateConstructorUsedError;
  double get pride => throw _privateConstructorUsedError;
  double get loneliness => throw _privateConstructorUsedError;
  double get pain => throw _privateConstructorUsedError;
  double get contempt => throw _privateConstructorUsedError;
  double get anticipation => throw _privateConstructorUsedError;
  double get trust =>
      throw _privateConstructorUsedError; // Overall sentiment score (-1.0 to 1.0)
  double get overallSentiment =>
      throw _privateConstructorUsedError; // Intensity of expression (0.0 to 1.0)
  double get intensity =>
      throw _privateConstructorUsedError; // Timestamp of this state
  DateTime? get timestamp =>
      throw _privateConstructorUsedError; // Source breakdown
  Map<String, double> get sourceContributions =>
      throw _privateConstructorUsedError;

  /// Serializes this EmotionState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EmotionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EmotionStateCopyWith<EmotionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EmotionStateCopyWith<$Res> {
  factory $EmotionStateCopyWith(
          EmotionState value, $Res Function(EmotionState) then) =
      _$EmotionStateCopyWithImpl<$Res, EmotionState>;
  @useResult
  $Res call(
      {double happiness,
      double sadness,
      double anger,
      double fear,
      double surprise,
      double disgust,
      double confusion,
      double pride,
      double loneliness,
      double pain,
      double contempt,
      double anticipation,
      double trust,
      double overallSentiment,
      double intensity,
      DateTime? timestamp,
      Map<String, double> sourceContributions});
}

/// @nodoc
class _$EmotionStateCopyWithImpl<$Res, $Val extends EmotionState>
    implements $EmotionStateCopyWith<$Res> {
  _$EmotionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EmotionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? happiness = null,
    Object? sadness = null,
    Object? anger = null,
    Object? fear = null,
    Object? surprise = null,
    Object? disgust = null,
    Object? confusion = null,
    Object? pride = null,
    Object? loneliness = null,
    Object? pain = null,
    Object? contempt = null,
    Object? anticipation = null,
    Object? trust = null,
    Object? overallSentiment = null,
    Object? intensity = null,
    Object? timestamp = freezed,
    Object? sourceContributions = null,
  }) {
    return _then(_value.copyWith(
      happiness: null == happiness
          ? _value.happiness
          : happiness // ignore: cast_nullable_to_non_nullable
              as double,
      sadness: null == sadness
          ? _value.sadness
          : sadness // ignore: cast_nullable_to_non_nullable
              as double,
      anger: null == anger
          ? _value.anger
          : anger // ignore: cast_nullable_to_non_nullable
              as double,
      fear: null == fear
          ? _value.fear
          : fear // ignore: cast_nullable_to_non_nullable
              as double,
      surprise: null == surprise
          ? _value.surprise
          : surprise // ignore: cast_nullable_to_non_nullable
              as double,
      disgust: null == disgust
          ? _value.disgust
          : disgust // ignore: cast_nullable_to_non_nullable
              as double,
      confusion: null == confusion
          ? _value.confusion
          : confusion // ignore: cast_nullable_to_non_nullable
              as double,
      pride: null == pride
          ? _value.pride
          : pride // ignore: cast_nullable_to_non_nullable
              as double,
      loneliness: null == loneliness
          ? _value.loneliness
          : loneliness // ignore: cast_nullable_to_non_nullable
              as double,
      pain: null == pain
          ? _value.pain
          : pain // ignore: cast_nullable_to_non_nullable
              as double,
      contempt: null == contempt
          ? _value.contempt
          : contempt // ignore: cast_nullable_to_non_nullable
              as double,
      anticipation: null == anticipation
          ? _value.anticipation
          : anticipation // ignore: cast_nullable_to_non_nullable
              as double,
      trust: null == trust
          ? _value.trust
          : trust // ignore: cast_nullable_to_non_nullable
              as double,
      overallSentiment: null == overallSentiment
          ? _value.overallSentiment
          : overallSentiment // ignore: cast_nullable_to_non_nullable
              as double,
      intensity: null == intensity
          ? _value.intensity
          : intensity // ignore: cast_nullable_to_non_nullable
              as double,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sourceContributions: null == sourceContributions
          ? _value.sourceContributions
          : sourceContributions // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EmotionStateImplCopyWith<$Res>
    implements $EmotionStateCopyWith<$Res> {
  factory _$$EmotionStateImplCopyWith(
          _$EmotionStateImpl value, $Res Function(_$EmotionStateImpl) then) =
      __$$EmotionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double happiness,
      double sadness,
      double anger,
      double fear,
      double surprise,
      double disgust,
      double confusion,
      double pride,
      double loneliness,
      double pain,
      double contempt,
      double anticipation,
      double trust,
      double overallSentiment,
      double intensity,
      DateTime? timestamp,
      Map<String, double> sourceContributions});
}

/// @nodoc
class __$$EmotionStateImplCopyWithImpl<$Res>
    extends _$EmotionStateCopyWithImpl<$Res, _$EmotionStateImpl>
    implements _$$EmotionStateImplCopyWith<$Res> {
  __$$EmotionStateImplCopyWithImpl(
      _$EmotionStateImpl _value, $Res Function(_$EmotionStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of EmotionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? happiness = null,
    Object? sadness = null,
    Object? anger = null,
    Object? fear = null,
    Object? surprise = null,
    Object? disgust = null,
    Object? confusion = null,
    Object? pride = null,
    Object? loneliness = null,
    Object? pain = null,
    Object? contempt = null,
    Object? anticipation = null,
    Object? trust = null,
    Object? overallSentiment = null,
    Object? intensity = null,
    Object? timestamp = freezed,
    Object? sourceContributions = null,
  }) {
    return _then(_$EmotionStateImpl(
      happiness: null == happiness
          ? _value.happiness
          : happiness // ignore: cast_nullable_to_non_nullable
              as double,
      sadness: null == sadness
          ? _value.sadness
          : sadness // ignore: cast_nullable_to_non_nullable
              as double,
      anger: null == anger
          ? _value.anger
          : anger // ignore: cast_nullable_to_non_nullable
              as double,
      fear: null == fear
          ? _value.fear
          : fear // ignore: cast_nullable_to_non_nullable
              as double,
      surprise: null == surprise
          ? _value.surprise
          : surprise // ignore: cast_nullable_to_non_nullable
              as double,
      disgust: null == disgust
          ? _value.disgust
          : disgust // ignore: cast_nullable_to_non_nullable
              as double,
      confusion: null == confusion
          ? _value.confusion
          : confusion // ignore: cast_nullable_to_non_nullable
              as double,
      pride: null == pride
          ? _value.pride
          : pride // ignore: cast_nullable_to_non_nullable
              as double,
      loneliness: null == loneliness
          ? _value.loneliness
          : loneliness // ignore: cast_nullable_to_non_nullable
              as double,
      pain: null == pain
          ? _value.pain
          : pain // ignore: cast_nullable_to_non_nullable
              as double,
      contempt: null == contempt
          ? _value.contempt
          : contempt // ignore: cast_nullable_to_non_nullable
              as double,
      anticipation: null == anticipation
          ? _value.anticipation
          : anticipation // ignore: cast_nullable_to_non_nullable
              as double,
      trust: null == trust
          ? _value.trust
          : trust // ignore: cast_nullable_to_non_nullable
              as double,
      overallSentiment: null == overallSentiment
          ? _value.overallSentiment
          : overallSentiment // ignore: cast_nullable_to_non_nullable
              as double,
      intensity: null == intensity
          ? _value.intensity
          : intensity // ignore: cast_nullable_to_non_nullable
              as double,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sourceContributions: null == sourceContributions
          ? _value._sourceContributions
          : sourceContributions // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EmotionStateImpl extends _EmotionState {
  const _$EmotionStateImpl(
      {this.happiness = 0.0,
      this.sadness = 0.0,
      this.anger = 0.0,
      this.fear = 0.0,
      this.surprise = 0.0,
      this.disgust = 0.0,
      this.confusion = 0.0,
      this.pride = 0.0,
      this.loneliness = 0.0,
      this.pain = 0.0,
      this.contempt = 0.0,
      this.anticipation = 0.0,
      this.trust = 0.0,
      this.overallSentiment = 0.0,
      this.intensity = 0.5,
      this.timestamp,
      final Map<String, double> sourceContributions = const {}})
      : _sourceContributions = sourceContributions,
        super._();

  factory _$EmotionStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$EmotionStateImplFromJson(json);

// Primary emotions (Ekman's basic emotions)
  @override
  @JsonKey()
  final double happiness;
  @override
  @JsonKey()
  final double sadness;
  @override
  @JsonKey()
  final double anger;
  @override
  @JsonKey()
  final double fear;
  @override
  @JsonKey()
  final double surprise;
  @override
  @JsonKey()
  final double disgust;
// Secondary/complex emotions
  @override
  @JsonKey()
  final double confusion;
  @override
  @JsonKey()
  final double pride;
  @override
  @JsonKey()
  final double loneliness;
  @override
  @JsonKey()
  final double pain;
  @override
  @JsonKey()
  final double contempt;
  @override
  @JsonKey()
  final double anticipation;
  @override
  @JsonKey()
  final double trust;
// Overall sentiment score (-1.0 to 1.0)
  @override
  @JsonKey()
  final double overallSentiment;
// Intensity of expression (0.0 to 1.0)
  @override
  @JsonKey()
  final double intensity;
// Timestamp of this state
  @override
  final DateTime? timestamp;
// Source breakdown
  final Map<String, double> _sourceContributions;
// Source breakdown
  @override
  @JsonKey()
  Map<String, double> get sourceContributions {
    if (_sourceContributions is EqualUnmodifiableMapView)
      return _sourceContributions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_sourceContributions);
  }

  @override
  String toString() {
    return 'EmotionState(happiness: $happiness, sadness: $sadness, anger: $anger, fear: $fear, surprise: $surprise, disgust: $disgust, confusion: $confusion, pride: $pride, loneliness: $loneliness, pain: $pain, contempt: $contempt, anticipation: $anticipation, trust: $trust, overallSentiment: $overallSentiment, intensity: $intensity, timestamp: $timestamp, sourceContributions: $sourceContributions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmotionStateImpl &&
            (identical(other.happiness, happiness) ||
                other.happiness == happiness) &&
            (identical(other.sadness, sadness) || other.sadness == sadness) &&
            (identical(other.anger, anger) || other.anger == anger) &&
            (identical(other.fear, fear) || other.fear == fear) &&
            (identical(other.surprise, surprise) ||
                other.surprise == surprise) &&
            (identical(other.disgust, disgust) || other.disgust == disgust) &&
            (identical(other.confusion, confusion) ||
                other.confusion == confusion) &&
            (identical(other.pride, pride) || other.pride == pride) &&
            (identical(other.loneliness, loneliness) ||
                other.loneliness == loneliness) &&
            (identical(other.pain, pain) || other.pain == pain) &&
            (identical(other.contempt, contempt) ||
                other.contempt == contempt) &&
            (identical(other.anticipation, anticipation) ||
                other.anticipation == anticipation) &&
            (identical(other.trust, trust) || other.trust == trust) &&
            (identical(other.overallSentiment, overallSentiment) ||
                other.overallSentiment == overallSentiment) &&
            (identical(other.intensity, intensity) ||
                other.intensity == intensity) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            const DeepCollectionEquality()
                .equals(other._sourceContributions, _sourceContributions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      happiness,
      sadness,
      anger,
      fear,
      surprise,
      disgust,
      confusion,
      pride,
      loneliness,
      pain,
      contempt,
      anticipation,
      trust,
      overallSentiment,
      intensity,
      timestamp,
      const DeepCollectionEquality().hash(_sourceContributions));

  /// Create a copy of EmotionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EmotionStateImplCopyWith<_$EmotionStateImpl> get copyWith =>
      __$$EmotionStateImplCopyWithImpl<_$EmotionStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EmotionStateImplToJson(
      this,
    );
  }
}

abstract class _EmotionState extends EmotionState {
  const factory _EmotionState(
      {final double happiness,
      final double sadness,
      final double anger,
      final double fear,
      final double surprise,
      final double disgust,
      final double confusion,
      final double pride,
      final double loneliness,
      final double pain,
      final double contempt,
      final double anticipation,
      final double trust,
      final double overallSentiment,
      final double intensity,
      final DateTime? timestamp,
      final Map<String, double> sourceContributions}) = _$EmotionStateImpl;
  const _EmotionState._() : super._();

  factory _EmotionState.fromJson(Map<String, dynamic> json) =
      _$EmotionStateImpl.fromJson;

// Primary emotions (Ekman's basic emotions)
  @override
  double get happiness;
  @override
  double get sadness;
  @override
  double get anger;
  @override
  double get fear;
  @override
  double get surprise;
  @override
  double get disgust; // Secondary/complex emotions
  @override
  double get confusion;
  @override
  double get pride;
  @override
  double get loneliness;
  @override
  double get pain;
  @override
  double get contempt;
  @override
  double get anticipation;
  @override
  double get trust; // Overall sentiment score (-1.0 to 1.0)
  @override
  double get overallSentiment; // Intensity of expression (0.0 to 1.0)
  @override
  double get intensity; // Timestamp of this state
  @override
  DateTime? get timestamp; // Source breakdown
  @override
  Map<String, double> get sourceContributions;

  /// Create a copy of EmotionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EmotionStateImplCopyWith<_$EmotionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FacialActionUnits _$FacialActionUnitsFromJson(Map<String, dynamic> json) {
  return _FacialActionUnits.fromJson(json);
}

/// @nodoc
mixin _$FacialActionUnits {
// Upper face
  double get au1InnerBrowRaise => throw _privateConstructorUsedError;
  double get au2OuterBrowRaise => throw _privateConstructorUsedError;
  double get au4BrowLower => throw _privateConstructorUsedError;
  double get au5UpperLidRaise => throw _privateConstructorUsedError;
  double get au6CheekRaise => throw _privateConstructorUsedError;
  double get au7LidTighten => throw _privateConstructorUsedError; // Lower face
  double get au9NoseWrinkle => throw _privateConstructorUsedError;
  double get au10UpperLipRaise => throw _privateConstructorUsedError;
  double get au12LipCornerPull => throw _privateConstructorUsedError; // smile
  double get au14Dimpler => throw _privateConstructorUsedError;
  double get au15LipCornerDepress =>
      throw _privateConstructorUsedError; // frown
  double get au17ChinRaise => throw _privateConstructorUsedError;
  double get au20LipStretch => throw _privateConstructorUsedError;
  double get au23LipTighten => throw _privateConstructorUsedError;
  double get au24LipPress => throw _privateConstructorUsedError;
  double get au25LipsPart => throw _privateConstructorUsedError;
  double get au26JawDrop => throw _privateConstructorUsedError;
  double get au27MouthStretch =>
      throw _privateConstructorUsedError; // Eye movement
  double get au61EyesLeft => throw _privateConstructorUsedError;
  double get au62EyesRight => throw _privateConstructorUsedError;
  double get au63EyesUp => throw _privateConstructorUsedError;
  double get au64EyesDown => throw _privateConstructorUsedError; // Misc
  double get au45Blink => throw _privateConstructorUsedError;
  double get au46Wink => throw _privateConstructorUsedError;

  /// Serializes this FacialActionUnits to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FacialActionUnits
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FacialActionUnitsCopyWith<FacialActionUnits> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FacialActionUnitsCopyWith<$Res> {
  factory $FacialActionUnitsCopyWith(
          FacialActionUnits value, $Res Function(FacialActionUnits) then) =
      _$FacialActionUnitsCopyWithImpl<$Res, FacialActionUnits>;
  @useResult
  $Res call(
      {double au1InnerBrowRaise,
      double au2OuterBrowRaise,
      double au4BrowLower,
      double au5UpperLidRaise,
      double au6CheekRaise,
      double au7LidTighten,
      double au9NoseWrinkle,
      double au10UpperLipRaise,
      double au12LipCornerPull,
      double au14Dimpler,
      double au15LipCornerDepress,
      double au17ChinRaise,
      double au20LipStretch,
      double au23LipTighten,
      double au24LipPress,
      double au25LipsPart,
      double au26JawDrop,
      double au27MouthStretch,
      double au61EyesLeft,
      double au62EyesRight,
      double au63EyesUp,
      double au64EyesDown,
      double au45Blink,
      double au46Wink});
}

/// @nodoc
class _$FacialActionUnitsCopyWithImpl<$Res, $Val extends FacialActionUnits>
    implements $FacialActionUnitsCopyWith<$Res> {
  _$FacialActionUnitsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FacialActionUnits
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? au1InnerBrowRaise = null,
    Object? au2OuterBrowRaise = null,
    Object? au4BrowLower = null,
    Object? au5UpperLidRaise = null,
    Object? au6CheekRaise = null,
    Object? au7LidTighten = null,
    Object? au9NoseWrinkle = null,
    Object? au10UpperLipRaise = null,
    Object? au12LipCornerPull = null,
    Object? au14Dimpler = null,
    Object? au15LipCornerDepress = null,
    Object? au17ChinRaise = null,
    Object? au20LipStretch = null,
    Object? au23LipTighten = null,
    Object? au24LipPress = null,
    Object? au25LipsPart = null,
    Object? au26JawDrop = null,
    Object? au27MouthStretch = null,
    Object? au61EyesLeft = null,
    Object? au62EyesRight = null,
    Object? au63EyesUp = null,
    Object? au64EyesDown = null,
    Object? au45Blink = null,
    Object? au46Wink = null,
  }) {
    return _then(_value.copyWith(
      au1InnerBrowRaise: null == au1InnerBrowRaise
          ? _value.au1InnerBrowRaise
          : au1InnerBrowRaise // ignore: cast_nullable_to_non_nullable
              as double,
      au2OuterBrowRaise: null == au2OuterBrowRaise
          ? _value.au2OuterBrowRaise
          : au2OuterBrowRaise // ignore: cast_nullable_to_non_nullable
              as double,
      au4BrowLower: null == au4BrowLower
          ? _value.au4BrowLower
          : au4BrowLower // ignore: cast_nullable_to_non_nullable
              as double,
      au5UpperLidRaise: null == au5UpperLidRaise
          ? _value.au5UpperLidRaise
          : au5UpperLidRaise // ignore: cast_nullable_to_non_nullable
              as double,
      au6CheekRaise: null == au6CheekRaise
          ? _value.au6CheekRaise
          : au6CheekRaise // ignore: cast_nullable_to_non_nullable
              as double,
      au7LidTighten: null == au7LidTighten
          ? _value.au7LidTighten
          : au7LidTighten // ignore: cast_nullable_to_non_nullable
              as double,
      au9NoseWrinkle: null == au9NoseWrinkle
          ? _value.au9NoseWrinkle
          : au9NoseWrinkle // ignore: cast_nullable_to_non_nullable
              as double,
      au10UpperLipRaise: null == au10UpperLipRaise
          ? _value.au10UpperLipRaise
          : au10UpperLipRaise // ignore: cast_nullable_to_non_nullable
              as double,
      au12LipCornerPull: null == au12LipCornerPull
          ? _value.au12LipCornerPull
          : au12LipCornerPull // ignore: cast_nullable_to_non_nullable
              as double,
      au14Dimpler: null == au14Dimpler
          ? _value.au14Dimpler
          : au14Dimpler // ignore: cast_nullable_to_non_nullable
              as double,
      au15LipCornerDepress: null == au15LipCornerDepress
          ? _value.au15LipCornerDepress
          : au15LipCornerDepress // ignore: cast_nullable_to_non_nullable
              as double,
      au17ChinRaise: null == au17ChinRaise
          ? _value.au17ChinRaise
          : au17ChinRaise // ignore: cast_nullable_to_non_nullable
              as double,
      au20LipStretch: null == au20LipStretch
          ? _value.au20LipStretch
          : au20LipStretch // ignore: cast_nullable_to_non_nullable
              as double,
      au23LipTighten: null == au23LipTighten
          ? _value.au23LipTighten
          : au23LipTighten // ignore: cast_nullable_to_non_nullable
              as double,
      au24LipPress: null == au24LipPress
          ? _value.au24LipPress
          : au24LipPress // ignore: cast_nullable_to_non_nullable
              as double,
      au25LipsPart: null == au25LipsPart
          ? _value.au25LipsPart
          : au25LipsPart // ignore: cast_nullable_to_non_nullable
              as double,
      au26JawDrop: null == au26JawDrop
          ? _value.au26JawDrop
          : au26JawDrop // ignore: cast_nullable_to_non_nullable
              as double,
      au27MouthStretch: null == au27MouthStretch
          ? _value.au27MouthStretch
          : au27MouthStretch // ignore: cast_nullable_to_non_nullable
              as double,
      au61EyesLeft: null == au61EyesLeft
          ? _value.au61EyesLeft
          : au61EyesLeft // ignore: cast_nullable_to_non_nullable
              as double,
      au62EyesRight: null == au62EyesRight
          ? _value.au62EyesRight
          : au62EyesRight // ignore: cast_nullable_to_non_nullable
              as double,
      au63EyesUp: null == au63EyesUp
          ? _value.au63EyesUp
          : au63EyesUp // ignore: cast_nullable_to_non_nullable
              as double,
      au64EyesDown: null == au64EyesDown
          ? _value.au64EyesDown
          : au64EyesDown // ignore: cast_nullable_to_non_nullable
              as double,
      au45Blink: null == au45Blink
          ? _value.au45Blink
          : au45Blink // ignore: cast_nullable_to_non_nullable
              as double,
      au46Wink: null == au46Wink
          ? _value.au46Wink
          : au46Wink // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FacialActionUnitsImplCopyWith<$Res>
    implements $FacialActionUnitsCopyWith<$Res> {
  factory _$$FacialActionUnitsImplCopyWith(_$FacialActionUnitsImpl value,
          $Res Function(_$FacialActionUnitsImpl) then) =
      __$$FacialActionUnitsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double au1InnerBrowRaise,
      double au2OuterBrowRaise,
      double au4BrowLower,
      double au5UpperLidRaise,
      double au6CheekRaise,
      double au7LidTighten,
      double au9NoseWrinkle,
      double au10UpperLipRaise,
      double au12LipCornerPull,
      double au14Dimpler,
      double au15LipCornerDepress,
      double au17ChinRaise,
      double au20LipStretch,
      double au23LipTighten,
      double au24LipPress,
      double au25LipsPart,
      double au26JawDrop,
      double au27MouthStretch,
      double au61EyesLeft,
      double au62EyesRight,
      double au63EyesUp,
      double au64EyesDown,
      double au45Blink,
      double au46Wink});
}

/// @nodoc
class __$$FacialActionUnitsImplCopyWithImpl<$Res>
    extends _$FacialActionUnitsCopyWithImpl<$Res, _$FacialActionUnitsImpl>
    implements _$$FacialActionUnitsImplCopyWith<$Res> {
  __$$FacialActionUnitsImplCopyWithImpl(_$FacialActionUnitsImpl _value,
      $Res Function(_$FacialActionUnitsImpl) _then)
      : super(_value, _then);

  /// Create a copy of FacialActionUnits
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? au1InnerBrowRaise = null,
    Object? au2OuterBrowRaise = null,
    Object? au4BrowLower = null,
    Object? au5UpperLidRaise = null,
    Object? au6CheekRaise = null,
    Object? au7LidTighten = null,
    Object? au9NoseWrinkle = null,
    Object? au10UpperLipRaise = null,
    Object? au12LipCornerPull = null,
    Object? au14Dimpler = null,
    Object? au15LipCornerDepress = null,
    Object? au17ChinRaise = null,
    Object? au20LipStretch = null,
    Object? au23LipTighten = null,
    Object? au24LipPress = null,
    Object? au25LipsPart = null,
    Object? au26JawDrop = null,
    Object? au27MouthStretch = null,
    Object? au61EyesLeft = null,
    Object? au62EyesRight = null,
    Object? au63EyesUp = null,
    Object? au64EyesDown = null,
    Object? au45Blink = null,
    Object? au46Wink = null,
  }) {
    return _then(_$FacialActionUnitsImpl(
      au1InnerBrowRaise: null == au1InnerBrowRaise
          ? _value.au1InnerBrowRaise
          : au1InnerBrowRaise // ignore: cast_nullable_to_non_nullable
              as double,
      au2OuterBrowRaise: null == au2OuterBrowRaise
          ? _value.au2OuterBrowRaise
          : au2OuterBrowRaise // ignore: cast_nullable_to_non_nullable
              as double,
      au4BrowLower: null == au4BrowLower
          ? _value.au4BrowLower
          : au4BrowLower // ignore: cast_nullable_to_non_nullable
              as double,
      au5UpperLidRaise: null == au5UpperLidRaise
          ? _value.au5UpperLidRaise
          : au5UpperLidRaise // ignore: cast_nullable_to_non_nullable
              as double,
      au6CheekRaise: null == au6CheekRaise
          ? _value.au6CheekRaise
          : au6CheekRaise // ignore: cast_nullable_to_non_nullable
              as double,
      au7LidTighten: null == au7LidTighten
          ? _value.au7LidTighten
          : au7LidTighten // ignore: cast_nullable_to_non_nullable
              as double,
      au9NoseWrinkle: null == au9NoseWrinkle
          ? _value.au9NoseWrinkle
          : au9NoseWrinkle // ignore: cast_nullable_to_non_nullable
              as double,
      au10UpperLipRaise: null == au10UpperLipRaise
          ? _value.au10UpperLipRaise
          : au10UpperLipRaise // ignore: cast_nullable_to_non_nullable
              as double,
      au12LipCornerPull: null == au12LipCornerPull
          ? _value.au12LipCornerPull
          : au12LipCornerPull // ignore: cast_nullable_to_non_nullable
              as double,
      au14Dimpler: null == au14Dimpler
          ? _value.au14Dimpler
          : au14Dimpler // ignore: cast_nullable_to_non_nullable
              as double,
      au15LipCornerDepress: null == au15LipCornerDepress
          ? _value.au15LipCornerDepress
          : au15LipCornerDepress // ignore: cast_nullable_to_non_nullable
              as double,
      au17ChinRaise: null == au17ChinRaise
          ? _value.au17ChinRaise
          : au17ChinRaise // ignore: cast_nullable_to_non_nullable
              as double,
      au20LipStretch: null == au20LipStretch
          ? _value.au20LipStretch
          : au20LipStretch // ignore: cast_nullable_to_non_nullable
              as double,
      au23LipTighten: null == au23LipTighten
          ? _value.au23LipTighten
          : au23LipTighten // ignore: cast_nullable_to_non_nullable
              as double,
      au24LipPress: null == au24LipPress
          ? _value.au24LipPress
          : au24LipPress // ignore: cast_nullable_to_non_nullable
              as double,
      au25LipsPart: null == au25LipsPart
          ? _value.au25LipsPart
          : au25LipsPart // ignore: cast_nullable_to_non_nullable
              as double,
      au26JawDrop: null == au26JawDrop
          ? _value.au26JawDrop
          : au26JawDrop // ignore: cast_nullable_to_non_nullable
              as double,
      au27MouthStretch: null == au27MouthStretch
          ? _value.au27MouthStretch
          : au27MouthStretch // ignore: cast_nullable_to_non_nullable
              as double,
      au61EyesLeft: null == au61EyesLeft
          ? _value.au61EyesLeft
          : au61EyesLeft // ignore: cast_nullable_to_non_nullable
              as double,
      au62EyesRight: null == au62EyesRight
          ? _value.au62EyesRight
          : au62EyesRight // ignore: cast_nullable_to_non_nullable
              as double,
      au63EyesUp: null == au63EyesUp
          ? _value.au63EyesUp
          : au63EyesUp // ignore: cast_nullable_to_non_nullable
              as double,
      au64EyesDown: null == au64EyesDown
          ? _value.au64EyesDown
          : au64EyesDown // ignore: cast_nullable_to_non_nullable
              as double,
      au45Blink: null == au45Blink
          ? _value.au45Blink
          : au45Blink // ignore: cast_nullable_to_non_nullable
              as double,
      au46Wink: null == au46Wink
          ? _value.au46Wink
          : au46Wink // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FacialActionUnitsImpl implements _FacialActionUnits {
  const _$FacialActionUnitsImpl(
      {this.au1InnerBrowRaise = 0.0,
      this.au2OuterBrowRaise = 0.0,
      this.au4BrowLower = 0.0,
      this.au5UpperLidRaise = 0.0,
      this.au6CheekRaise = 0.0,
      this.au7LidTighten = 0.0,
      this.au9NoseWrinkle = 0.0,
      this.au10UpperLipRaise = 0.0,
      this.au12LipCornerPull = 0.0,
      this.au14Dimpler = 0.0,
      this.au15LipCornerDepress = 0.0,
      this.au17ChinRaise = 0.0,
      this.au20LipStretch = 0.0,
      this.au23LipTighten = 0.0,
      this.au24LipPress = 0.0,
      this.au25LipsPart = 0.0,
      this.au26JawDrop = 0.0,
      this.au27MouthStretch = 0.0,
      this.au61EyesLeft = 0.0,
      this.au62EyesRight = 0.0,
      this.au63EyesUp = 0.0,
      this.au64EyesDown = 0.0,
      this.au45Blink = 0.0,
      this.au46Wink = 0.0});

  factory _$FacialActionUnitsImpl.fromJson(Map<String, dynamic> json) =>
      _$$FacialActionUnitsImplFromJson(json);

// Upper face
  @override
  @JsonKey()
  final double au1InnerBrowRaise;
  @override
  @JsonKey()
  final double au2OuterBrowRaise;
  @override
  @JsonKey()
  final double au4BrowLower;
  @override
  @JsonKey()
  final double au5UpperLidRaise;
  @override
  @JsonKey()
  final double au6CheekRaise;
  @override
  @JsonKey()
  final double au7LidTighten;
// Lower face
  @override
  @JsonKey()
  final double au9NoseWrinkle;
  @override
  @JsonKey()
  final double au10UpperLipRaise;
  @override
  @JsonKey()
  final double au12LipCornerPull;
// smile
  @override
  @JsonKey()
  final double au14Dimpler;
  @override
  @JsonKey()
  final double au15LipCornerDepress;
// frown
  @override
  @JsonKey()
  final double au17ChinRaise;
  @override
  @JsonKey()
  final double au20LipStretch;
  @override
  @JsonKey()
  final double au23LipTighten;
  @override
  @JsonKey()
  final double au24LipPress;
  @override
  @JsonKey()
  final double au25LipsPart;
  @override
  @JsonKey()
  final double au26JawDrop;
  @override
  @JsonKey()
  final double au27MouthStretch;
// Eye movement
  @override
  @JsonKey()
  final double au61EyesLeft;
  @override
  @JsonKey()
  final double au62EyesRight;
  @override
  @JsonKey()
  final double au63EyesUp;
  @override
  @JsonKey()
  final double au64EyesDown;
// Misc
  @override
  @JsonKey()
  final double au45Blink;
  @override
  @JsonKey()
  final double au46Wink;

  @override
  String toString() {
    return 'FacialActionUnits(au1InnerBrowRaise: $au1InnerBrowRaise, au2OuterBrowRaise: $au2OuterBrowRaise, au4BrowLower: $au4BrowLower, au5UpperLidRaise: $au5UpperLidRaise, au6CheekRaise: $au6CheekRaise, au7LidTighten: $au7LidTighten, au9NoseWrinkle: $au9NoseWrinkle, au10UpperLipRaise: $au10UpperLipRaise, au12LipCornerPull: $au12LipCornerPull, au14Dimpler: $au14Dimpler, au15LipCornerDepress: $au15LipCornerDepress, au17ChinRaise: $au17ChinRaise, au20LipStretch: $au20LipStretch, au23LipTighten: $au23LipTighten, au24LipPress: $au24LipPress, au25LipsPart: $au25LipsPart, au26JawDrop: $au26JawDrop, au27MouthStretch: $au27MouthStretch, au61EyesLeft: $au61EyesLeft, au62EyesRight: $au62EyesRight, au63EyesUp: $au63EyesUp, au64EyesDown: $au64EyesDown, au45Blink: $au45Blink, au46Wink: $au46Wink)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FacialActionUnitsImpl &&
            (identical(other.au1InnerBrowRaise, au1InnerBrowRaise) ||
                other.au1InnerBrowRaise == au1InnerBrowRaise) &&
            (identical(other.au2OuterBrowRaise, au2OuterBrowRaise) ||
                other.au2OuterBrowRaise == au2OuterBrowRaise) &&
            (identical(other.au4BrowLower, au4BrowLower) ||
                other.au4BrowLower == au4BrowLower) &&
            (identical(other.au5UpperLidRaise, au5UpperLidRaise) ||
                other.au5UpperLidRaise == au5UpperLidRaise) &&
            (identical(other.au6CheekRaise, au6CheekRaise) ||
                other.au6CheekRaise == au6CheekRaise) &&
            (identical(other.au7LidTighten, au7LidTighten) ||
                other.au7LidTighten == au7LidTighten) &&
            (identical(other.au9NoseWrinkle, au9NoseWrinkle) ||
                other.au9NoseWrinkle == au9NoseWrinkle) &&
            (identical(other.au10UpperLipRaise, au10UpperLipRaise) ||
                other.au10UpperLipRaise == au10UpperLipRaise) &&
            (identical(other.au12LipCornerPull, au12LipCornerPull) ||
                other.au12LipCornerPull == au12LipCornerPull) &&
            (identical(other.au14Dimpler, au14Dimpler) ||
                other.au14Dimpler == au14Dimpler) &&
            (identical(other.au15LipCornerDepress, au15LipCornerDepress) ||
                other.au15LipCornerDepress == au15LipCornerDepress) &&
            (identical(other.au17ChinRaise, au17ChinRaise) ||
                other.au17ChinRaise == au17ChinRaise) &&
            (identical(other.au20LipStretch, au20LipStretch) ||
                other.au20LipStretch == au20LipStretch) &&
            (identical(other.au23LipTighten, au23LipTighten) ||
                other.au23LipTighten == au23LipTighten) &&
            (identical(other.au24LipPress, au24LipPress) ||
                other.au24LipPress == au24LipPress) &&
            (identical(other.au25LipsPart, au25LipsPart) ||
                other.au25LipsPart == au25LipsPart) &&
            (identical(other.au26JawDrop, au26JawDrop) ||
                other.au26JawDrop == au26JawDrop) &&
            (identical(other.au27MouthStretch, au27MouthStretch) ||
                other.au27MouthStretch == au27MouthStretch) &&
            (identical(other.au61EyesLeft, au61EyesLeft) ||
                other.au61EyesLeft == au61EyesLeft) &&
            (identical(other.au62EyesRight, au62EyesRight) ||
                other.au62EyesRight == au62EyesRight) &&
            (identical(other.au63EyesUp, au63EyesUp) ||
                other.au63EyesUp == au63EyesUp) &&
            (identical(other.au64EyesDown, au64EyesDown) ||
                other.au64EyesDown == au64EyesDown) &&
            (identical(other.au45Blink, au45Blink) ||
                other.au45Blink == au45Blink) &&
            (identical(other.au46Wink, au46Wink) ||
                other.au46Wink == au46Wink));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        au1InnerBrowRaise,
        au2OuterBrowRaise,
        au4BrowLower,
        au5UpperLidRaise,
        au6CheekRaise,
        au7LidTighten,
        au9NoseWrinkle,
        au10UpperLipRaise,
        au12LipCornerPull,
        au14Dimpler,
        au15LipCornerDepress,
        au17ChinRaise,
        au20LipStretch,
        au23LipTighten,
        au24LipPress,
        au25LipsPart,
        au26JawDrop,
        au27MouthStretch,
        au61EyesLeft,
        au62EyesRight,
        au63EyesUp,
        au64EyesDown,
        au45Blink,
        au46Wink
      ]);

  /// Create a copy of FacialActionUnits
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FacialActionUnitsImplCopyWith<_$FacialActionUnitsImpl> get copyWith =>
      __$$FacialActionUnitsImplCopyWithImpl<_$FacialActionUnitsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FacialActionUnitsImplToJson(
      this,
    );
  }
}

abstract class _FacialActionUnits implements FacialActionUnits {
  const factory _FacialActionUnits(
      {final double au1InnerBrowRaise,
      final double au2OuterBrowRaise,
      final double au4BrowLower,
      final double au5UpperLidRaise,
      final double au6CheekRaise,
      final double au7LidTighten,
      final double au9NoseWrinkle,
      final double au10UpperLipRaise,
      final double au12LipCornerPull,
      final double au14Dimpler,
      final double au15LipCornerDepress,
      final double au17ChinRaise,
      final double au20LipStretch,
      final double au23LipTighten,
      final double au24LipPress,
      final double au25LipsPart,
      final double au26JawDrop,
      final double au27MouthStretch,
      final double au61EyesLeft,
      final double au62EyesRight,
      final double au63EyesUp,
      final double au64EyesDown,
      final double au45Blink,
      final double au46Wink}) = _$FacialActionUnitsImpl;

  factory _FacialActionUnits.fromJson(Map<String, dynamic> json) =
      _$FacialActionUnitsImpl.fromJson;

// Upper face
  @override
  double get au1InnerBrowRaise;
  @override
  double get au2OuterBrowRaise;
  @override
  double get au4BrowLower;
  @override
  double get au5UpperLidRaise;
  @override
  double get au6CheekRaise;
  @override
  double get au7LidTighten; // Lower face
  @override
  double get au9NoseWrinkle;
  @override
  double get au10UpperLipRaise;
  @override
  double get au12LipCornerPull; // smile
  @override
  double get au14Dimpler;
  @override
  double get au15LipCornerDepress; // frown
  @override
  double get au17ChinRaise;
  @override
  double get au20LipStretch;
  @override
  double get au23LipTighten;
  @override
  double get au24LipPress;
  @override
  double get au25LipsPart;
  @override
  double get au26JawDrop;
  @override
  double get au27MouthStretch; // Eye movement
  @override
  double get au61EyesLeft;
  @override
  double get au62EyesRight;
  @override
  double get au63EyesUp;
  @override
  double get au64EyesDown; // Misc
  @override
  double get au45Blink;
  @override
  double get au46Wink;

  /// Create a copy of FacialActionUnits
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FacialActionUnitsImplCopyWith<_$FacialActionUnitsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
