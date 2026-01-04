import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../domain/emotion_state.dart';
import '../../../core/api/api_client.dart';

/// Provides the current emotion state from the backend.
final emotionStateProvider = StateNotifierProvider<EmotionStateNotifier, AsyncValue<EmotionState>>((ref) {
  final repository = ref.watch(sentimentRepositoryProvider);
  return EmotionStateNotifier(repository);
});

/// Provides the sentiment repository.
final sentimentRepositoryProvider = Provider<SentimentRepository>((ref) {
  return SentimentRepository(ref.watch(apiClientProvider));
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

  EmotionStateNotifier(this._repository) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Try WebSocket first, fall back to polling
    try {
      await _connectWebSocket();
    } catch (e) {
      _startPolling();
    }
  }

  Future<void> _connectWebSocket() async {
    _subscription = _repository.streamSentiment().listen(
      (emotion) {
        state = AsyncValue.data(emotion);
      },
      onError: (error) {
        // Fall back to polling on WebSocket error
        _startPolling();
      },
    );
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await refresh();
    });
    // Initial fetch
    refresh();
  }

  Future<void> refresh() async {
    try {
      final emotion = await _repository.getCurrentSentiment();
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
  Future<EmotionState> getCurrentSentiment() async {
    final response = await _client.get('/api/v1/sentiment/current');
    return EmotionState.fromJson(response);
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

  /// Fetches sentiment breakdown by source.
  Future<Map<String, EmotionState>> getBySource() async {
    final response = await _client.get('/api/v1/sentiment/sources');
    return (response['sources'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, EmotionState.fromJson(value as Map<String, dynamic>)),
    );
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
