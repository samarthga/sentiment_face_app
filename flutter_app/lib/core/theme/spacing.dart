import 'package:flutter/material.dart';

/// Consistent spacing system following 4px grid.
abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Standard animation durations.
abstract class AppDurations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 400);
}

/// Standard animation curves.
abstract class AppCurves {
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve emphasis = Curves.easeOutBack;
  static const Curve decelerate = Curves.decelerate;
  static const Curve bounce = Curves.elasticOut;
}
