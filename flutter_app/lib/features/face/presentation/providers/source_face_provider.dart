import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/source_emotion_state.dart';
import '../../domain/contextual_prompt_builder.dart';
import '../../../settings/domain/expression_type.dart';
import '../../../settings/data/settings_provider.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/config/api_config.dart';

/// Request object for source face image generation.
class SourceFaceRequest {
  final SourceEmotionState sourceEmotion;
  final ExpressionType expressionType;

  const SourceFaceRequest({
    required this.sourceEmotion,
    required this.expressionType,
  });

  /// Cache key for this request.
  String get cacheKey {
    final emotion = sourceEmotion.emotion;
    final intensityBucket = _getIntensityBucket(emotion.dominantIntensity);
    final topicHash = sourceEmotion.topTopic.hashCode.abs() % 1000;
    return '${sourceEmotion.source}_${emotion.dominantEmotion}_${intensityBucket}_${topicHash}_${expressionType.name}';
  }

  String _getIntensityBucket(double intensity) {
    if (intensity > 0.66) return 'high';
    if (intensity > 0.33) return 'medium';
    return 'low';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceFaceRequest &&
          runtimeType == other.runtimeType &&
          cacheKey == other.cacheKey;

  @override
  int get hashCode => cacheKey.hashCode;
}

/// LRU cache for generated face images.
class _ImageCache {
  final int maxSize;
  final int maxMemoryBytes;
  final Map<String, Uint8List> _cache = {};
  final List<String> _accessOrder = [];
  int _currentMemoryUsage = 0;

  _ImageCache({this.maxSize = 30, this.maxMemoryBytes = 50 * 1024 * 1024}); // 50MB

  Uint8List? get(String key) {
    if (_cache.containsKey(key)) {
      // Move to end of access order (most recently used)
      _accessOrder.remove(key);
      _accessOrder.add(key);
      return _cache[key];
    }
    return null;
  }

  void put(String key, Uint8List data) {
    // If key exists, update it
    if (_cache.containsKey(key)) {
      _currentMemoryUsage -= _cache[key]!.length;
      _accessOrder.remove(key);
    }

    // Evict if necessary
    while ((_cache.length >= maxSize || _currentMemoryUsage + data.length > maxMemoryBytes) &&
        _accessOrder.isNotEmpty) {
      final lruKey = _accessOrder.removeAt(0);
      _currentMemoryUsage -= _cache[lruKey]!.length;
      _cache.remove(lruKey);
    }

    // Add new entry
    _cache[key] = data;
    _accessOrder.add(key);
    _currentMemoryUsage += data.length;
  }

  bool containsKey(String key) => _cache.containsKey(key);

  void clear() {
    _cache.clear();
    _accessOrder.clear();
    _currentMemoryUsage = 0;
  }
}

/// Global image cache instance.
final _imageCache = _ImageCache();

/// Provider for Gemini service (shared with realistic_face.dart).
final sourceFaceGeminiProvider = Provider<GeminiService>((ref) {
  return GeminiService(apiKey: ApiConfig.geminiApiKey);
});

/// Provider for generating face images for a specific source.
final sourceFaceImageProvider = FutureProvider.family<Uint8List?, SourceFaceRequest>(
  (ref, request) async {
    final cacheKey = request.cacheKey;

    // Check cache first
    final cached = _imageCache.get(cacheKey);
    if (cached != null) {
      debugPrint('Cache hit for source face: $cacheKey');
      return cached;
    }

    // Generate new image
    final gemini = ref.watch(sourceFaceGeminiProvider);
    final prompt = ContextualPromptBuilder.buildSourcePrompt(
      emotion: request.sourceEmotion.emotion,
      topic: request.sourceEmotion.topTopic,
      sourceName: request.sourceEmotion.source,
      expressionType: request.expressionType,
    );

    debugPrint('Generating source face for ${request.sourceEmotion.source} with topic "${request.sourceEmotion.topTopic}"');
    debugPrint('Prompt: $prompt');

    // Try Gemini 2.0 first
    var imageData = await gemini.generateFaceWithGemini2(prompt: prompt);

    // Fallback to Imagen if available
    imageData ??= await gemini.generateFaceImage(prompt: prompt);

    // Cache the result
    if (imageData != null) {
      _imageCache.put(cacheKey, imageData);
    }

    return imageData;
  },
);

/// Provider that creates SourceFaceRequest from SourceEmotionState.
/// This auto-watches the expression type setting.
final sourceFaceRequestProvider = Provider.family<SourceFaceRequest, SourceEmotionState>(
  (ref, sourceEmotion) {
    final expressionType = ref.watch(expressionTypeProvider);
    return SourceFaceRequest(
      sourceEmotion: sourceEmotion,
      expressionType: expressionType,
    );
  },
);

/// Clear the image cache (useful when settings change significantly).
void clearSourceFaceCache() {
  _imageCache.clear();
}
