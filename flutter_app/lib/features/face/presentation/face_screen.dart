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
        // Header with emotion label
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSearching ? 'Topic: $searchQuery' : 'Internet Mood',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isSearching ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getEmotionLabel(emotion.dominantEmotion),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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

        // Realistic Face
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: RealisticFaceWidget(emotion: emotion),
          ),
        ),

        const SizedBox(height: 16),

        // Emotion breakdown
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SourceBreakdown(emotion: emotion),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  String _getEmotionLabel(String emotion) {
    return emotion[0].toUpperCase() + emotion.substring(1);
  }
}
