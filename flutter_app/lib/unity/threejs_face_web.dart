import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../features/face/domain/emotion_state.dart';

/// Web implementation of the 3D face using Three.js
class ThreeJsFaceWidget extends StatefulWidget {
  final EmotionState emotion;

  const ThreeJsFaceWidget({super.key, required this.emotion});

  @override
  State<ThreeJsFaceWidget> createState() => _ThreeJsFaceWidgetState();
}

class _ThreeJsFaceWidgetState extends State<ThreeJsFaceWidget> {
  static bool _viewTypeRegistered = false;
  static const String _viewType = 'threejs-face-view';
  html.IFrameElement? _iframe;

  @override
  void initState() {
    super.initState();
    _registerViewFactory();
  }

  void _registerViewFactory() {
    if (!_viewTypeRegistered) {
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        _iframe = html.IFrameElement()
          ..src = 'threejs_face.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'accelerometer; autoplay; encrypted-media; gyroscope';
        return _iframe!;
      });
      _viewTypeRegistered = true;
    }
  }

  @override
  void didUpdateWidget(ThreeJsFaceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.emotion != oldWidget.emotion) {
      _sendEmotionToThreeJs();
    }
  }

  void _sendEmotionToThreeJs() {
    if (_iframe?.contentWindow != null) {
      final message = jsonEncode({
        'type': 'setEmotion',
        'happiness': widget.emotion.happiness,
        'sadness': widget.emotion.sadness,
        'anger': widget.emotion.anger,
        'fear': widget.emotion.fear,
        'surprise': widget.emotion.surprise,
        'disgust': widget.emotion.disgust,
      });
      _iframe!.contentWindow!.postMessage(message, '*');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Send emotion after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendEmotionToThreeJs();
    });

    return const HtmlElementView(viewType: _viewType);
  }
}
