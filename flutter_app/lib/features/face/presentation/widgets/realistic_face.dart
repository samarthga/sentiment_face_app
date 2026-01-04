import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/emotion_state.dart';
import '../../domain/emotion_prompt_builder.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/config/api_config.dart';

/// Provider for Gemini service.
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(apiKey: ApiConfig.geminiApiKey);
});

/// Cache for generated face images.
/// Key is the dominant emotion + intensity bucket.
final _imageCache = <String, Uint8List>{};

/// Provider for generating face images based on emotion state.
final faceImageProvider = FutureProvider.family<Uint8List?, EmotionState>((ref, emotion) async {
  // Create cache key based on dominant emotion and intensity bucket
  final cacheKey = _getCacheKey(emotion);

  // Check cache first
  if (_imageCache.containsKey(cacheKey)) {
    return _imageCache[cacheKey];
  }

  // Generate new image
  final gemini = ref.watch(geminiServiceProvider);
  final prompt = EmotionPromptBuilder.buildShortPrompt(emotion);

  debugPrint('Generating face with prompt:\n$prompt');

  // Try Gemini 2.0 first (has image generation)
  var imageData = await gemini.generateFaceWithGemini2(prompt: prompt);

  // Fallback to Imagen if available
  imageData ??= await gemini.generateFaceImage(prompt: prompt);

  // Cache the result
  if (imageData != null) {
    _imageCache[cacheKey] = imageData;

    // Limit cache size to 20 images
    if (_imageCache.length > 20) {
      _imageCache.remove(_imageCache.keys.first);
    }
  }

  return imageData;
});

/// Create a cache key from emotion state.
String _getCacheKey(EmotionState emotion) {
  final dominant = emotion.dominantEmotion;
  // Bucket intensity into 3 levels: low, medium, high
  final intensity = emotion.dominantIntensity;
  String intensityBucket;
  if (intensity > 0.66) {
    intensityBucket = 'high';
  } else if (intensity > 0.33) {
    intensityBucket = 'medium';
  } else {
    intensityBucket = 'low';
  }
  return '${dominant}_$intensityBucket';
}

/// A hyper-realistic face widget that uses Gemini to generate faces.
class RealisticFaceWidget extends ConsumerStatefulWidget {
  final EmotionState emotion;

  const RealisticFaceWidget({super.key, required this.emotion});

  @override
  ConsumerState<RealisticFaceWidget> createState() => _RealisticFaceWidgetState();
}

class _RealisticFaceWidgetState extends ConsumerState<RealisticFaceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageAsync = ref.watch(faceImageProvider(widget.emotion));

    return Container(
      color: Colors.grey.shade900,
      child: imageAsync.when(
        data: (imageData) {
          if (imageData != null) {
            return _buildFaceImage(imageData);
          }
          return _buildFallbackFace();
        },
        loading: () => _buildLoadingState(),
        error: (e, _) => _buildFallbackFace(error: e.toString()),
      ),
    );
  }

  Widget _buildFaceImage(Uint8List imageData) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: SizedBox.expand(
        key: ValueKey(imageData.hashCode),
        child: Image.memory(
          imageData,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Animated gradient background
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8 + (_pulseController.value * 0.2),
                  colors: [
                    _getEmotionColor(widget.emotion.dominantEmotion).withOpacity(0.3),
                    Colors.grey.shade800,
                  ],
                ),
              ),
            );
          },
        ),

        // Face silhouette placeholder
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing face icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.1),
                    child: Icon(
                      Icons.face,
                      size: 120,
                      color: Colors.white.withOpacity(0.3 + (_pulseController.value * 0.2)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Generating face...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(
                    _getEmotionColor(widget.emotion.dominantEmotion),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Emotion: ${widget.emotion.dominantEmotion.toUpperCase()}',
                  style: TextStyle(
                    color: _getEmotionColor(widget.emotion.dominantEmotion),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackFace({String? error}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Placeholder face
        CustomPaint(
          painter: _FallbackFacePainter(emotion: widget.emotion),
          child: const SizedBox.expand(),
        ),

        // Error message if any
        if (error != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Image generation unavailable',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                    onPressed: () {
                      ref.invalidate(faceImageProvider(widget.emotion));
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happiness':
        return Colors.amber;
      case 'sadness':
        return Colors.blue;
      case 'anger':
        return Colors.red;
      case 'fear':
        return Colors.purple;
      case 'surprise':
        return Colors.orange;
      case 'disgust':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

/// Overlay showing current emotion state.
class _EmotionOverlay extends StatelessWidget {
  final EmotionState emotion;

  const _EmotionOverlay({required this.emotion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getEmotionIcon(emotion.dominantEmotion),
            color: _getEmotionColor(emotion.dominantEmotion),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            emotion.dominantEmotion.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(emotion.dominantIntensity * 100).toInt()}%',
            style: TextStyle(
              color: _getEmotionColor(emotion.dominantEmotion),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happiness':
        return Icons.sentiment_very_satisfied;
      case 'sadness':
        return Icons.sentiment_very_dissatisfied;
      case 'anger':
        return Icons.mood_bad;
      case 'fear':
        return Icons.psychology;
      case 'surprise':
        return Icons.face;
      case 'disgust':
        return Icons.sick;
      default:
        return Icons.face;
    }
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happiness':
        return Colors.amber;
      case 'sadness':
        return Colors.blue;
      case 'anger':
        return Colors.red;
      case 'fear':
        return Colors.purple;
      case 'surprise':
        return Colors.orange;
      case 'disgust':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

/// Fallback face painter when Gemini is unavailable.
class _FallbackFacePainter extends CustomPainter {
  final EmotionState emotion;

  _FallbackFacePainter({required this.emotion});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final faceWidth = size.width * 0.65;
    final faceHeight = size.height * 0.75;

    // Face shape
    final faceRect = Rect.fromCenter(
      center: center,
      width: faceWidth,
      height: faceHeight,
    );

    // Gradient skin
    final skinGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 1.2,
      colors: [
        const Color(0xFFFAE0C8),
        const Color(0xFFE8C4A0),
        const Color(0xFFD4A574),
      ],
    );

    final facePaint = Paint()
      ..shader = skinGradient.createShader(faceRect);
    canvas.drawOval(faceRect, facePaint);

    // Simple facial features
    _drawEyes(canvas, center, faceWidth);
    _drawMouth(canvas, center, faceWidth);
  }

  void _drawEyes(Canvas canvas, Offset center, double faceWidth) {
    final eyeY = center.dy - faceWidth * 0.1;
    final eyeSpacing = faceWidth * 0.2;
    final eyeRadius = faceWidth * 0.08;

    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = const Color(0xFF3D2314);

    for (final side in [-1.0, 1.0]) {
      final eyeCenter = Offset(center.dx + eyeSpacing * side, eyeY);
      canvas.drawCircle(eyeCenter, eyeRadius, eyePaint);
      canvas.drawCircle(eyeCenter, eyeRadius * 0.5, pupilPaint);
    }
  }

  void _drawMouth(Canvas canvas, Offset center, double faceWidth) {
    final mouthY = center.dy + faceWidth * 0.2;
    final mouthWidth = faceWidth * 0.3;

    final mouthPaint = Paint()
      ..color = const Color(0xFFCC8080)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final smile = emotion.happiness - emotion.sadness;

    final path = Path()
      ..moveTo(center.dx - mouthWidth / 2, mouthY)
      ..quadraticBezierTo(
        center.dx,
        mouthY + smile * 30,
        center.dx + mouthWidth / 2,
        mouthY,
      );

    canvas.drawPath(path, mouthPaint);
  }

  @override
  bool shouldRepaint(_FallbackFacePainter oldDelegate) =>
      emotion != oldDelegate.emotion;
}
