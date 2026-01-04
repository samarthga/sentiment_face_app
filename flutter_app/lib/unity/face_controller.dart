import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import '../features/face/domain/emotion_state.dart';
import '../features/face/domain/emotion_mapper.dart';

// Conditional import for web
import 'threejs_face_stub.dart' if (dart.library.html) 'threejs_face_web.dart';

// Note: In production, uncomment flutter_unity_widget import
// import 'package:flutter_unity_widget/flutter_unity_widget.dart';

/// Widget that renders the 3D face using Unity.
/// Communicates emotion state to Unity via message passing.
class UnityFaceWidget extends StatefulWidget {
  final EmotionState emotion;

  const UnityFaceWidget({super.key, required this.emotion});

  @override
  State<UnityFaceWidget> createState() => _UnityFaceWidgetState();
}

class _UnityFaceWidgetState extends State<UnityFaceWidget>
    with SingleTickerProviderStateMixin {
  // UnityWidgetController? _unityController;
  late AnimationController _animationController;
  EmotionState? _previousEmotion;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(UnityFaceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.emotion != oldWidget.emotion) {
      _previousEmotion = oldWidget.emotion;
      _animationController.forward(from: 0);
      _sendEmotionToUnity(widget.emotion);
    }
  }

  void _sendEmotionToUnity(EmotionState emotion) {
    final actionUnits = EmotionMapper.toActionUnits(emotion);

    // Convert to JSON for Unity
    final message = jsonEncode({
      'type': 'setEmotion',
      'actionUnits': {
        'innerBrowRaise': actionUnits.au1InnerBrowRaise,
        'outerBrowRaise': actionUnits.au2OuterBrowRaise,
        'browLower': actionUnits.au4BrowLower,
        'upperLidRaise': actionUnits.au5UpperLidRaise,
        'cheekRaise': actionUnits.au6CheekRaise,
        'lidTighten': actionUnits.au7LidTighten,
        'noseWrinkle': actionUnits.au9NoseWrinkle,
        'upperLipRaise': actionUnits.au10UpperLipRaise,
        'lipCornerPull': actionUnits.au12LipCornerPull,
        'lipCornerDepress': actionUnits.au15LipCornerDepress,
        'chinRaise': actionUnits.au17ChinRaise,
        'lipStretch': actionUnits.au20LipStretch,
        'lipsPart': actionUnits.au25LipsPart,
        'jawDrop': actionUnits.au26JawDrop,
        'mouthStretch': actionUnits.au27MouthStretch,
      },
      'transitionDuration': 0.5,
    });

    // Send to Unity controller when available
    // _unityController?.postMessage('FaceController', 'SetEmotion', message);
    debugPrint('Unity message: $message');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Three.js on web, placeholder on other platforms
    if (kIsWeb) {
      return ThreeJsFaceWidget(emotion: widget.emotion);
    }

    // Placeholder UI until Unity is integrated for mobile
    // Replace with actual UnityWidget in production:
    //
    // return UnityWidget(
    //   onUnityCreated: (controller) {
    //     _unityController = controller;
    //     _sendEmotionToUnity(widget.emotion);
    //   },
    //   onUnityMessage: (message) {
    //     debugPrint('From Unity: $message');
    //   },
    // );

    return _PlaceholderFace(
      emotion: widget.emotion,
      animation: _animationController,
    );
  }
}

/// Placeholder face widget for development/testing.
/// Shows a stylized face that responds to emotion state.
class _PlaceholderFace extends StatelessWidget {
  final EmotionState emotion;
  final Animation<double> animation;

  const _PlaceholderFace({
    required this.emotion,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _FacePainter(emotion: emotion),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _FacePainter extends CustomPainter {
  final EmotionState emotion;

  _FacePainter({required this.emotion});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final faceRadius = size.width * 0.35;

    // Face background
    final facePaint = Paint()
      ..color = const Color(0xFFFFDBB4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, faceRadius, facePaint);

    // Face outline
    final outlinePaint = Paint()
      ..color = const Color(0xFFD4A574)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, faceRadius, outlinePaint);

    // Eyes
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pupilPaint = Paint()
      ..color = const Color(0xFF4A3728)
      ..style = PaintingStyle.fill;

    final eyeY = center.dy - faceRadius * 0.15;
    final eyeSpacing = faceRadius * 0.35;
    final eyeRadius = faceRadius * 0.15;

    // Left eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - eyeSpacing, eyeY),
        width: eyeRadius * 2,
        height: eyeRadius * 1.5 * (1 - emotion.anger * 0.3),
      ),
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx - eyeSpacing, eyeY),
      eyeRadius * 0.5,
      pupilPaint,
    );

    // Right eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + eyeSpacing, eyeY),
        width: eyeRadius * 2,
        height: eyeRadius * 1.5 * (1 - emotion.anger * 0.3),
      ),
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + eyeSpacing, eyeY),
      eyeRadius * 0.5,
      pupilPaint,
    );

    // Eyebrows
    final browPaint = Paint()
      ..color = const Color(0xFF4A3728)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final browY = eyeY - eyeRadius * 1.5;
    final browAngle = emotion.anger * 0.3 - emotion.sadness * 0.2;

    // Left eyebrow
    canvas.drawLine(
      Offset(center.dx - eyeSpacing - eyeRadius, browY + browAngle * 20),
      Offset(center.dx - eyeSpacing + eyeRadius, browY - browAngle * 20),
      browPaint,
    );

    // Right eyebrow
    canvas.drawLine(
      Offset(center.dx + eyeSpacing - eyeRadius, browY - browAngle * 20),
      Offset(center.dx + eyeSpacing + eyeRadius, browY + browAngle * 20),
      browPaint,
    );

    // Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFFCC7B7B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final mouthY = center.dy + faceRadius * 0.35;
    final mouthWidth = faceRadius * 0.5;
    final smileAmount = emotion.happiness - emotion.sadness - emotion.anger * 0.5;

    final mouthPath = Path();
    mouthPath.moveTo(center.dx - mouthWidth, mouthY);
    mouthPath.quadraticBezierTo(
      center.dx,
      mouthY + smileAmount * 40,
      center.dx + mouthWidth,
      mouthY,
    );
    canvas.drawPath(mouthPath, mouthPaint);

    // Emotion label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '3D Face (Unity)\nPlaceholder',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        size.height - 50,
      ),
    );
  }

  @override
  bool shouldRepaint(_FacePainter oldDelegate) {
    return emotion != oldDelegate.emotion;
  }
}
