import 'package:flutter/material.dart';
import '../../domain/emotion_state.dart';

class SourceBreakdown extends StatelessWidget {
  final EmotionState emotion;

  const SourceBreakdown({super.key, required this.emotion});

  @override
  Widget build(BuildContext context) {
    final emotions = _getTopEmotions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emotion Breakdown',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: emotions.map((e) => Expanded(
              child: _EmotionBar(
                label: e['label'] as String,
                value: e['value'] as double,
                color: e['color'] as Color,
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getTopEmotions() {
    final emotions = [
      {'label': 'Happy', 'value': emotion.happiness, 'color': Colors.yellow},
      {'label': 'Sad', 'value': emotion.sadness, 'color': Colors.blue},
      {'label': 'Angry', 'value': emotion.anger, 'color': Colors.red},
      {'label': 'Fear', 'value': emotion.fear, 'color': Colors.purple},
      {'label': 'Surprise', 'value': emotion.surprise, 'color': Colors.orange},
    ];

    emotions.sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));
    return emotions.take(5).toList();
  }
}

class _EmotionBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _EmotionBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.bottomCenter,
                heightFactor: value.clamp(0.05, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${(value * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
