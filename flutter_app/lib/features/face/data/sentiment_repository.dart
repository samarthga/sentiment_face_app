import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../domain/emotion_state.dart';
import '../domain/source_emotion_state.dart';
import '../../../core/api/api_client.dart';

/// Information about a data source.
class SourceInfo {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const SourceInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Available data sources with metadata.
final availableSourcesProvider = Provider<List<SourceInfo>>((ref) => const [
  SourceInfo(
    id: 'reddit',
    name: 'Reddit',
    icon: Icons.forum,
    color: Color(0xFFFF4500),
  ),
  SourceInfo(
    id: 'hackernews',
    name: 'HackerNews',
    icon: Icons.computer,
    color: Color(0xFFFF6600),
  ),
  SourceInfo(
    id: 'rss',
    name: 'RSS Feeds',
    icon: Icons.rss_feed,
    color: Color(0xFFEE802F),
  ),
  SourceInfo(
    id: 'bluesky',
    name: 'Bluesky',
    icon: Icons.cloud,
    color: Color(0xFF0085FF),
  ),
  SourceInfo(
    id: 'truthsocial',
    name: 'Truth Social',
    icon: Icons.verified,
    color: Color(0xFF5448EE),
  ),
]);

/// Currently selected sources (all enabled by default).
final selectedSourcesProvider = StateProvider<Set<String>>((ref) {
  final available = ref.watch(availableSourcesProvider);
  return available.map((s) => s.id).toSet();
});

/// Provides the current emotion state from the backend.
/// This provider watches selectedSourcesProvider and invalidates when sources change.
final emotionStateProvider = StateNotifierProvider<EmotionStateNotifier, AsyncValue<EmotionState>>((ref) {
  final repository = ref.watch(sentimentRepositoryProvider);
  // Watch selectedSources - provider will be recreated when sources change
  final selectedSources = ref.watch(selectedSourcesProvider);
  return EmotionStateNotifier(repository, selectedSources.toList());
});

/// Provides the sentiment repository.
final sentimentRepositoryProvider = Provider<SentimentRepository>((ref) {
  return SentimentRepository(ref.watch(apiClientProvider));
});

/// Provider for per-source emotions with topic information.
final sourceEmotionsProvider = FutureProvider.autoDispose<List<SourceEmotionState>>((ref) async {
  final repository = ref.watch(sentimentRepositoryProvider);
  final selectedSources = ref.watch(selectedSourcesProvider);
  return repository.getSourceEmotions(sources: selectedSources.toList());
});

/// Global search query state - shared across all pages.
final globalSearchQueryProvider = StateProvider<String?>((ref) => null);

/// Global search result provider.
final globalSearchResultProvider = FutureProvider.autoDispose<SearchResult?>((ref) async {
  final query = ref.watch(globalSearchQueryProvider);
  if (query == null || query.isEmpty) return null;

  final repository = ref.watch(sentimentRepositoryProvider);
  return repository.searchTopic(query);
});

/// Combined emotion state that uses search results when searching.
final effectiveEmotionProvider = Provider<AsyncValue<EmotionState>>((ref) {
  final searchQuery = ref.watch(globalSearchQueryProvider);
  final baseEmotion = ref.watch(emotionStateProvider);

  // If not searching, return base emotion
  if (searchQuery == null || searchQuery.isEmpty) {
    return baseEmotion;
  }

  // If searching, try to use search result emotions
  final searchResult = ref.watch(globalSearchResultProvider);

  return searchResult.when(
    data: (result) {
      if (result?.emotion != null) {
        // Convert search result emotion map to EmotionState
        final emotionMap = result!.emotion!;
        return AsyncValue.data(EmotionState(
          happiness: (emotionMap['happiness'] as num?)?.toDouble() ?? 0.0,
          sadness: (emotionMap['sadness'] as num?)?.toDouble() ?? 0.0,
          anger: (emotionMap['anger'] as num?)?.toDouble() ?? 0.0,
          fear: (emotionMap['fear'] as num?)?.toDouble() ?? 0.0,
          surprise: (emotionMap['surprise'] as num?)?.toDouble() ?? 0.0,
          disgust: (emotionMap['disgust'] as num?)?.toDouble() ?? 0.0,
          overallSentiment: (emotionMap['overall_sentiment'] as num?)?.toDouble() ?? 0.0,
          intensity: (emotionMap['intensity'] as num?)?.toDouble() ?? 0.5,
          timestamp: emotionMap['timestamp'] != null
              ? DateTime.tryParse(emotionMap['timestamp'] as String)
              : DateTime.now(),
        ));
      }
      return baseEmotion;
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => baseEmotion, // Fall back to base on error
  );
});

/// Notifier that manages emotion state updates.
class EmotionStateNotifier extends StateNotifier<AsyncValue<EmotionState>> {
  final SentimentRepository _repository;
  StreamSubscription<EmotionState>? _subscription;
  Timer? _pollingTimer;
  List<String> _currentSources;

  EmotionStateNotifier(this._repository, List<String> initialSources)
      : _currentSources = initialSources,
        super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Use polling to support source filtering
    // (WebSocket doesn't support source filtering)
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Initial fetch immediately
    refresh();
    // Then poll every 30 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await refresh();
    });
  }

  /// Update the sources filter and refresh.
  Future<void> updateSources(Set<String> sources) async {
    _currentSources = sources.toList();
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final emotion = await _repository.getCurrentSentiment(sources: _currentSources);
      state = AsyncValue.data(emotion);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }
}

/// Repository for fetching sentiment data from the backend.
class SentimentRepository {
  final ApiClient _client;
  WebSocketChannel? _channel;

  SentimentRepository(this._client);

  /// Fetches the current aggregated sentiment.
  /// Optionally filter by specific sources.
  Future<EmotionState> getCurrentSentiment({List<String>? sources}) async {
    final queryParams = <String, String>{};
    if (sources != null && sources.isNotEmpty) {
      queryParams['sources'] = sources.join(',');
    }
    final response = await _client.get('/api/v1/sentiment/current', queryParams: queryParams.isNotEmpty ? queryParams : null);
    return EmotionState.fromJson(response);
  }

  /// Fetches available sources from the backend.
  Future<List<String>> getAvailableSources() async {
    final response = await _client.get('/api/v1/sentiment/available-sources');
    return List<String>.from(response['sources'] as List);
  }

  /// Fetches historical sentiment data with topics.
  Future<HistoryResponse> getHistory({
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (from != null) queryParams['from'] = from.toIso8601String();
    if (to != null) queryParams['to'] = to.toIso8601String();

    final response = await _client.get('/api/v1/sentiment/history', queryParams: queryParams);
    return HistoryResponse.fromJson(response);
  }

  /// Fetches trending topics.
  Future<List<TopicData>> getTrendingTopics({int hours = 1, int limit = 10}) async {
    final response = await _client.get('/api/v1/sentiment/topics', queryParams: {
      'hours': hours.toString(),
      'limit': limit.toString(),
    });
    return (response['topics'] as List)
        .map((e) => TopicData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Search for a specific topic.
  Future<SearchResult> searchTopic(String query) async {
    final response = await _client.post('/api/v1/sentiment/search', queryParams: {
      'query': query,
    });
    return SearchResult.fromJson(response);
  }

  /// Clear active search.
  Future<void> clearSearch() async {
    await _client.delete('/api/v1/sentiment/search');
  }

  /// Get search status.
  Future<SearchStatus> getSearchStatus() async {
    final response = await _client.get('/api/v1/sentiment/search/status');
    return SearchStatus.fromJson(response);
  }

  /// Get topics associated with each emotion.
  Future<Map<String, List<String>>> getEmotionTopics() async {
    final response = await _client.get('/api/v1/sentiment/emotion-topics');
    return (response as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, List<String>.from(value as List)),
    );
  }

  /// Fetches sentiment breakdown by source (legacy - returns just emotions).
  Future<Map<String, EmotionState>> getBySource() async {
    final response = await _client.get('/api/v1/sentiment/sources');
    final sources = response['sources'] as Map<String, dynamic>;
    return sources.map((key, value) {
      final sourceData = value as Map<String, dynamic>;
      final emotionData = sourceData['emotion'] as Map<String, dynamic>;
      return MapEntry(key, EmotionState.fromJson(emotionData));
    });
  }

  /// Fetches per-source emotions with topics (new API).
  Future<List<SourceEmotionState>> getSourceEmotions({List<String>? sources}) async {
    final queryParams = <String, String>{};
    if (sources != null && sources.isNotEmpty) {
      queryParams['sources'] = sources.join(',');
    }

    final response = await _client.get(
      '/api/v1/sentiment/sources',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    final sourcesData = response['sources'] as Map<String, dynamic>;
    return sourcesData.entries.map((entry) {
      final data = entry.value as Map<String, dynamic>;
      // Map the nested emotion data
      final emotionData = data['emotion'] as Map<String, dynamic>;
      return SourceEmotionState(
        source: entry.key,
        emotion: EmotionState.fromJson(emotionData),
        topTopic: data['top_topic'] as String? ?? '',
        topicSentiment: (data['topic_sentiment'] as num?)?.toDouble() ?? 0.0,
        sampleTitles: List<String>.from(data['sample_titles'] as List? ?? []),
        postCount: (data['post_count'] as num?)?.toInt() ?? 0,
        lastUpdated: data['last_updated'] != null
            ? DateTime.tryParse(data['last_updated'] as String)
            : null,
      );
    }).toList();
  }

  /// Streams real-time sentiment updates via WebSocket.
  Stream<EmotionState> streamSentiment() {
    _channel?.sink.close();
    _channel = WebSocketChannel.connect(
      Uri.parse('${_client.wsBaseUrl}/api/v1/sentiment/stream'),
    );

    return _channel!.stream.map((data) {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      return EmotionState.fromJson(json);
    });
  }

  void dispose() {
    _channel?.sink.close();
  }
}

/// History entry with topics.
class HistoryEntry {
  final DateTime timestamp;
  final Map<String, double> emotions;
  final double overallSentiment;
  final double intensity;
  final List<TopicData> topics;
  final Map<String, int> sources;
  final String dominantEmotion;

  HistoryEntry({
    required this.timestamp,
    required this.emotions,
    required this.overallSentiment,
    required this.intensity,
    required this.topics,
    required this.sources,
    required this.dominantEmotion,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      emotions: Map<String, double>.from(
        (json['emotions'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      overallSentiment: (json['overallSentiment'] as num?)?.toDouble() ?? 0.0,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.5,
      topics: (json['topics'] as List?)
          ?.map((e) => TopicData.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      sources: Map<String, int>.from(
        (json['sources'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ) ?? {},
      ),
      dominantEmotion: json['dominantEmotion'] as String? ?? 'neutral',
    );
  }
}

/// Topic data from sentiment analysis.
class TopicData {
  final String topic;
  final int count;
  final double sentiment;
  final int? mentions;
  final double? avgSentiment;
  final String? dominantEmotion;

  TopicData({
    required this.topic,
    this.count = 0,
    this.sentiment = 0.0,
    this.mentions,
    this.avgSentiment,
    this.dominantEmotion,
  });

  factory TopicData.fromJson(Map<String, dynamic> json) {
    return TopicData(
      topic: json['topic'] as String,
      count: (json['count'] as num?)?.toInt() ?? 0,
      sentiment: (json['sentiment'] as num?)?.toDouble() ?? 0.0,
      mentions: (json['mentions'] as num?)?.toInt(),
      avgSentiment: (json['avgSentiment'] as num?)?.toDouble(),
      dominantEmotion: json['dominantEmotion'] as String?,
    );
  }
}

/// Response from history endpoint.
class HistoryResponse {
  final List<HistoryEntry> data;
  final int count;
  final String? from;
  final String? to;

  HistoryResponse({
    required this.data,
    required this.count,
    this.from,
    this.to,
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    return HistoryResponse(
      data: (json['data'] as List?)
          ?.map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      count: json['count'] as int? ?? 0,
      from: json['from'] as String?,
      to: json['to'] as String?,
    );
  }
}

/// Result from topic search.
class SearchResult {
  final String query;
  final int count;
  final String? message;
  final Map<String, dynamic>? emotion;
  final List<TopicData> topics;
  final Map<String, int> sources;

  SearchResult({
    required this.query,
    required this.count,
    this.message,
    this.emotion,
    required this.topics,
    required this.sources,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      query: json['query'] as String,
      count: json['count'] as int? ?? 0,
      message: json['message'] as String?,
      emotion: json['emotion'] as Map<String, dynamic>?,
      topics: (json['topics'] as List?)
          ?.map((e) => TopicData.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      sources: Map<String, int>.from(
        (json['sources'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ) ?? {},
      ),
    );
  }
}

/// Search status.
class SearchStatus {
  final bool active;
  final String? topic;

  SearchStatus({
    required this.active,
    this.topic,
  });

  factory SearchStatus.fromJson(Map<String, dynamic> json) {
    return SearchStatus(
      active: json['active'] as bool? ?? false,
      topic: json['topic'] as String?,
    );
  }
}
