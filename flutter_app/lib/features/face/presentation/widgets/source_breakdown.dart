import 'package:flutter/material.dart';
import '../../domain/emotion_state.dart';

class SourceBreakdown extends StatelessWidget {
  final EmotionState emotion;

  const SourceBreakdown({super.key, required this.emotion});

  @override
  Widget build(BuildContext context) {
    final emotions = _getTopEmotions();

    return Row(
      children: emotions.map((e) => Expanded(
        child: _EmotionBar(
          label: e['label'] as String,
          value: e['value'] as double,
          color: e['color'] as Color,
        ),
      )).toList(),
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
    return Tooltip(
      message: '$label: ${(value * 100).toInt()}%',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.bottomCenter,
                  heightFactor: value.clamp(0.05, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.substring(0, 1),
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
