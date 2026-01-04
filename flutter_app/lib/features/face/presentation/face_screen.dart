import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sentiment_repository.dart';
import '../domain/emotion_state.dart';
import 'widgets/realistic_face.dart';
import 'widgets/emotion_indicator.dart';
import 'widgets/source_breakdown.dart';

class FaceScreen extends ConsumerWidget {
  const FaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use effective emotion which reflects search results when searching
    final emotionAsync = ref.watch(effectiveEmotionProvider);

    return Scaffold(
      body: SafeArea(
        child: emotionAsync.when(
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

    return Column(
      children: [
        // Compact header with emotion label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSearching ? 'Topic: $searchQuery' : 'Internet Mood',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSearching ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getEmotionLabel(emotion.dominantEmotion),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              EmotionIndicator(emotion: emotion),
            ],
          ),
        ),

        // Realistic Face - takes maximum space, fills completely
        Expanded(
          child: RealisticFaceWidget(emotion: emotion),
        ),

        // Compact emotion breakdown at bottom
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SizedBox(
            height: 60,
            child: SourceBreakdown(emotion: emotion),
          ),
        ),
      ],
    );
  }

  String _getEmotionLabel(String emotion) {
    return emotion[0].toUpperCase() + emotion.substring(1);
  }
}
