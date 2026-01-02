import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../face/data/sentiment_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emotionAsync = ref.watch(emotionStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: emotionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (emotion) => ListView(
            children: [
              _StatCard(
                title: 'Overall Sentiment',
                value: '${(emotion.overallSentiment * 100).toStringAsFixed(1)}%',
                subtitle: emotion.overallSentiment > 0 ? 'Positive' : 'Negative',
                icon: emotion.overallSentiment > 0
                    ? Icons.sentiment_satisfied
                    : Icons.sentiment_dissatisfied,
                color: emotion.overallSentiment > 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              _StatCard(
                title: 'Dominant Emotion',
                value: emotion.dominantEmotion.toUpperCase(),
                subtitle: '${(emotion.dominantIntensity * 100).toStringAsFixed(0)}% intensity',
                icon: Icons.psychology,
                color: Colors.purple,
              ),
              const SizedBox(height: 16),
              _StatCard(
                title: 'Expression Intensity',
                value: '${(emotion.intensity * 100).toStringAsFixed(0)}%',
                subtitle: 'How strongly emotions are being expressed',
                icon: Icons.speed,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                'Emotion Breakdown',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _EmotionRow(label: 'Happiness', value: emotion.happiness),
              _EmotionRow(label: 'Sadness', value: emotion.sadness),
              _EmotionRow(label: 'Anger', value: emotion.anger),
              _EmotionRow(label: 'Fear', value: emotion.fear),
              _EmotionRow(label: 'Surprise', value: emotion.surprise),
              _EmotionRow(label: 'Disgust', value: emotion.disgust),
              _EmotionRow(label: 'Confusion', value: emotion.confusion),
              _EmotionRow(label: 'Pride', value: emotion.pride),
              _EmotionRow(label: 'Loneliness', value: emotion.loneliness),
              _EmotionRow(label: 'Pain', value: emotion.pain),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmotionRow extends StatelessWidget {
  final String label;
  final double value;

  const _EmotionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${(value * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation(_getEmotionColor(label)),
          ),
        ],
      ),
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happiness':
        return Colors.yellow;
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
      case 'confusion':
        return Colors.teal;
      case 'pride':
        return Colors.amber;
      case 'loneliness':
        return Colors.indigo;
      case 'pain':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }
}
