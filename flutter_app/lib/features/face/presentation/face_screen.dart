import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sentiment_repository.dart';
import '../domain/emotion_state.dart';
import 'widgets/realistic_face.dart';
import 'widgets/emotion_indicator.dart';
import 'widgets/source_breakdown.dart';
import 'widgets/source_chips.dart';
import '../../../core/theme/emotion_colors.dart';

class FaceScreen extends ConsumerWidget {
  const FaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emotionAsync = ref.watch(effectiveEmotionProvider);

    return Scaffold(
      body: emotionAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Reading the internet\'s mood...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(emotionStateProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (emotion) => _FaceContent(emotion: emotion),
      ),
    );
  }
}

class _FaceContent extends ConsumerWidget {
  final EmotionState emotion;

  const _FaceContent({required this.emotion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(globalSearchQueryProvider);
    final isSearching = searchQuery != null && searchQuery.isNotEmpty;
    final emotionColor = EmotionColors.getColor(emotion.dominantEmotion);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            emotionColor.withOpacity( 0.08),
            Colors.black,
          ],
          stops: const [0.0, 0.4],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSearching ? 'Topic: $searchQuery' : 'Internet Mood',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSearching
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade500,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getEmotionLabel(emotion.dominantEmotion),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  EmotionIndicator(emotion: emotion),
                ],
              ),
            ),

            // Face — takes all remaining space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: RealisticFaceWidget(emotion: emotion),
              ),
            ),

            // Source chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                height: 36,
                child: SourceChips(emotion: emotion),
              ),
            ),

            // Emotion breakdown
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: SizedBox(
                height: 44,
                child: SourceBreakdown(emotion: emotion),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmotionLabel(String emotion) {
    return emotion[0].toUpperCase() + emotion.substring(1);
  }
}
