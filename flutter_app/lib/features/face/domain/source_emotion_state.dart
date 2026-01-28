import 'emotion_state.dart';

/// Emotion state for a specific data source with topic information.
class SourceEmotionState {
  /// Name of the data source (e.g., 'reddit', 'hackernews').
  final String source;

  /// The emotion state calculated from this source's content.
  final EmotionState emotion;

  /// The most relevant/frequent topic driving the emotion.
  final String topTopic;

  /// Sentiment score specifically for the top topic (-1 to 1).
  final double topicSentiment;

  /// 2-3 sample headlines/titles from this source.
  final List<String> sampleTitles;

  /// Number of posts analyzed from this source.
  final int postCount;

  /// When this source was last scraped/analyzed.
  final DateTime? lastUpdated;

  const SourceEmotionState({
    required this.source,
    required this.emotion,
    this.topTopic = '',
    this.topicSentiment = 0.0,
    this.sampleTitles = const [],
    this.postCount = 0,
    this.lastUpdated,
  });

  factory SourceEmotionState.fromJson(Map<String, dynamic> json) {
    return SourceEmotionState(
      source: json['source'] as String,
      emotion: EmotionState.fromJson(json['emotion'] as Map<String, dynamic>),
      topTopic: json['top_topic'] as String? ?? '',
      topicSentiment: (json['topic_sentiment'] as num?)?.toDouble() ?? 0.0,
      sampleTitles: List<String>.from(json['sample_titles'] as List? ?? []),
      postCount: (json['post_count'] as num?)?.toInt() ?? 0,
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'emotion': emotion.toJson(),
      'top_topic': topTopic,
      'topic_sentiment': topicSentiment,
      'sample_titles': sampleTitles,
      'post_count': postCount,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceEmotionState &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          topTopic == other.topTopic &&
          postCount == other.postCount;

  @override
  int get hashCode => source.hashCode ^ topTopic.hashCode ^ postCount.hashCode;
}
