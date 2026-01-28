import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animation extension methods for widgets.
extension WidgetAnimationExtensions on Widget {
  /// Standard fade-in entrance animation.
  Widget fadeInSlide({Duration? delay, Duration? duration}) {
    return animate(delay: delay)
        .fadeIn(duration: duration ?? 300.ms, curve: Curves.easeOut)
        .slideY(begin: 0.1, end: 0, duration: duration ?? 300.ms);
  }

  /// Staggered list item animation.
  Widget staggeredItem(int index, {Duration baseDelay = const Duration(milliseconds: 50)}) {
    return animate(delay: Duration(milliseconds: baseDelay.inMilliseconds * index))
        .fadeIn(duration: 200.ms)
        .slideX(begin: -0.05, end: 0, duration: 200.ms);
  }

  /// Shimmer loading effect.
  Widget shimmerEffect() {
    return animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1500.ms, color: Colors.white24);
  }

  /// Pulse animation for emphasis.
  Widget pulseEffect() {
    return animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 800.ms,
        );
  }

  /// Scale on tap feedback.
  Widget scaleOnTap({double scale = 0.95}) {
    return animate()
        .scale(
          begin: const Offset(1, 1),
          end: Offset(scale, scale),
          duration: 100.ms,
          curve: Curves.easeInOut,
        );
  }

  /// Card entrance animation.
  Widget cardEntrance({int index = 0}) {
    return animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.15, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  /// Bounce in animation.
  Widget bounceIn({Duration? delay}) {
    return animate(delay: delay)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 200.ms);
  }
}
