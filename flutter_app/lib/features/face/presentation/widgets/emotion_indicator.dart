import 'package:flutter/material.dart';
import '../../domain/emotion_state.dart';

class EmotionIndicator extends StatelessWidget {
  final EmotionState emotion;

  const EmotionIndicator({super.key, required this.emotion});

  @override
  Widget build(BuildContext context) {
    final sentiment = emotion.overallSentiment;
    final color = _getSentimentColor(sentiment);
    final label = _getSentimentLabel(sentiment);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getSentimentIcon(sentiment),
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSentimentColor(double sentiment) {
    if (sentiment > 0.3) return Colors.green;
    if (sentiment > 0) return Colors.lightGreen;
    if (sentiment > -0.3) return Colors.orange;
    return Colors.red;
  }

  String _getSentimentLabel(double sentiment) {
    if (sentiment > 0.5) return 'Very Positive';
    if (sentiment > 0.2) return 'Positive';
    if (sentiment > -0.2) return 'Neutral';
    if (sentiment > -0.5) return 'Negative';
    return 'Very Negative';
  }

  IconData _getSentimentIcon(double sentiment) {
    if (sentiment > 0.3) return Icons.trending_up;
    if (sentiment > -0.3) return Icons.trending_flat;
    return Icons.trending_down;
  }
}
