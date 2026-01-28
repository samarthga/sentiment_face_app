import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A configurable skeleton loader with shimmer effect.
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1500.ms, color: Colors.grey.shade600);
  }
}

/// Skeleton for stat cards on dashboard.
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SkeletonLoader(width: 56, height: 56, borderRadius: 12),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLoader(height: 12, width: 80),
                  SizedBox(height: 8),
                  SkeletonLoader(height: 24, width: 120),
                  SizedBox(height: 4),
                  SkeletonLoader(height: 12, width: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for emotion breakdown rows.
class EmotionRowSkeleton extends StatelessWidget {
  const EmotionRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: const [
          SkeletonLoader(width: 8, height: 8, borderRadius: 4),
          SizedBox(width: 8),
          SkeletonLoader(width: 60, height: 14),
          Spacer(),
          SkeletonLoader(width: 40, height: 14),
        ],
      ),
    );
  }
}

/// Full dashboard skeleton for loading state.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Source chips skeleton
        const SizedBox(
          height: 36,
          child: Row(
            children: [
              SkeletonLoader(width: 70, height: 32, borderRadius: 16),
              SizedBox(width: 8),
              SkeletonLoader(width: 70, height: 32, borderRadius: 16),
              SizedBox(width: 8),
              SkeletonLoader(width: 70, height: 32, borderRadius: 16),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stat cards skeletons
        const StatCardSkeleton(),
        const SizedBox(height: 16),
        const StatCardSkeleton(),
        const SizedBox(height: 16),
        const StatCardSkeleton(),

        const SizedBox(height: 24),

        // Section header skeleton
        const SkeletonLoader(width: 150, height: 24),
        const SizedBox(height: 16),

        // Emotion rows skeletons
        ...List.generate(6, (_) => const EmotionRowSkeleton()),
      ],
    );
  }
}
