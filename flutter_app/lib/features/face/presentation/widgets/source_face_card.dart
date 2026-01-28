import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/source_emotion_state.dart';
import '../../data/sentiment_repository.dart';
import '../providers/source_face_provider.dart';
import '../../../../core/theme/emotion_colors.dart';

/// Card widget displaying a source's face with emotion and topic.
class SourceFaceCard extends ConsumerStatefulWidget {
  final SourceEmotionState sourceEmotion;
  final int index;

  const SourceFaceCard({
    super.key,
    required this.sourceEmotion,
    this.index = 0,
  });

  @override
  ConsumerState<SourceFaceCard> createState() => _SourceFaceCardState();
}

class _SourceFaceCardState extends ConsumerState<SourceFaceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(sourceFaceRequestProvider(widget.sourceEmotion));
    final imageAsync = ref.watch(sourceFaceImageProvider(request));
    final sources = ref.watch(availableSourcesProvider);
    final sourceInfo = sources.firstWhere(
      (s) => s.id.toLowerCase() == widget.sourceEmotion.source.toLowerCase(),
      orElse: () => SourceInfo(
        id: widget.sourceEmotion.source,
        name: widget.sourceEmotion.source,
        icon: Icons.source,
        color: Colors.grey,
      ),
    );

    final emotionColor = EmotionColors.getColor(
      widget.sourceEmotion.emotion.dominantEmotion,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Face image or loading/fallback
          imageAsync.when(
            data: (imageData) {
              if (imageData != null) {
                return _buildFaceImage(imageData);
              }
              return _buildFallback(emotionColor);
            },
            loading: () => _buildLoadingState(emotionColor),
            error: (e, _) => _buildFallback(emotionColor, error: e.toString()),
          ),

          // Gradient overlay for text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.2, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Source info (top-left)
          Positioned(
            top: 8,
            left: 8,
            child: _SourceBadge(
              icon: sourceInfo.icon,
              color: sourceInfo.color,
              name: sourceInfo.name,
            ),
          ),

          // Emotion badge (top-right)
          Positioned(
            top: 8,
            right: 8,
            child: _EmotionBadge(
              emotion: widget.sourceEmotion.emotion.dominantEmotion,
              color: emotionColor,
            ),
          ),

          // Topic label (bottom)
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: _TopicLabel(
              topic: widget.sourceEmotion.topTopic,
              postCount: widget.sourceEmotion.postCount,
              color: emotionColor,
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 100 * widget.index))
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildFaceImage(Uint8List imageData) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: Image.memory(
        imageData,
        key: ValueKey(imageData.hashCode),
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }

  Widget _buildLoadingState(Color emotionColor) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2 * _shimmerController.value, 0),
              end: Alignment(-0.5 + 2 * _shimmerController.value, 0),
              colors: [
                Colors.grey.shade900,
                emotionColor.withOpacity(0.3),
                Colors.grey.shade900,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.face,
                  size: 48,
                  color: emotionColor.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(emotionColor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallback(Color emotionColor, {String? error}) {
    return Container(
      color: Colors.grey.shade900,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.face,
              size: 64,
              color: emotionColor.withOpacity(0.5),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Image unavailable',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Badge showing source icon and name.
class _SourceBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;

  const _SourceBadge({
    required this.icon,
    required this.color,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge showing dominant emotion.
class _EmotionBadge extends StatelessWidget {
  final String emotion;
  final Color color;

  const _EmotionBadge({
    required this.emotion,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        emotion.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Label showing the topic driving the emotion.
class _TopicLabel extends StatelessWidget {
  final String topic;
  final int postCount;
  final Color color;

  const _TopicLabel({
    required this.topic,
    required this.postCount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  topic.isNotEmpty ? '"$topic"' : 'General sentiment',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (postCount > 0) ...[
            const SizedBox(height: 2),
            Text(
              '$postCount posts analyzed',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
