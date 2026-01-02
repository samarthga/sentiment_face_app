import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sentiment_repository.dart';
import '../domain/emotion_state.dart';
import '../../../unity/face_controller.dart';
import 'widgets/emotion_indicator.dart';
import 'widgets/source_breakdown.dart';

class FaceScreen extends ConsumerWidget {
  const FaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emotionAsync = ref.watch(emotionStateProvider);

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

class _FaceContent extends StatelessWidget {
  final EmotionState emotion;

  const _FaceContent({required this.emotion});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with emotion label
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Internet Mood',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    _getEmotionLabel(emotion.dominantEmotion),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              EmotionIndicator(emotion: emotion),
            ],
          ),
        ),

        // 3D Face (Unity widget)
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black26,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: UnityFaceWidget(emotion: emotion),
            ),
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
