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

  /// Fetches historical sentiment data.
  Future<List<EmotionState>> getHistory({
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
    return (response['data'] as List)
        .map((e) => EmotionState.fromJson(e as Map<String, dynamic>))
        .toList();
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
