import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/source_emotion_state.dart';
import 'source_face_card.dart';

/// Dynamic grid layout for multiple source face cards.
/// Adapts layout based on number of sources:
/// - 1 source: Full width
/// - 2 sources: Side by side
/// - 3 sources: 2 top + 1 bottom centered
/// - 4 sources: 2x2 grid
/// - 5 sources: 3 top + 2 bottom
class MultiFaceGrid extends ConsumerWidget {
  final List<SourceEmotionState> sourceEmotions;
  final double spacing;

  const MultiFaceGrid({
    super.key,
    required this.sourceEmotions,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sourceEmotions.isEmpty) {
      return const Center(
        child: Text(
          'No sources selected',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildGrid(constraints);
      },
    );
  }

  Widget _buildGrid(BoxConstraints constraints) {
    final count = sourceEmotions.length;

    switch (count) {
      case 1:
        return _buildSingleFace();
      case 2:
        return _buildTwoFaces();
      case 3:
        return _buildThreeFaces();
      case 4:
        return _buildFourFaces();
      case 5:
        return _buildFiveFaces();
      default:
        // For more than 5, use a simple grid
        return _buildMultipleFaces();
    }
  }

  /// Single face - full size
  Widget _buildSingleFace() {
    return Padding(
      padding: EdgeInsets.all(spacing),
      child: SourceFaceCard(
        sourceEmotion: sourceEmotions[0],
        index: 0,
      ),
    );
  }

  /// Two faces - side by side
  Widget _buildTwoFaces() {
    return Padding(
      padding: EdgeInsets.all(spacing),
      child: Row(
        children: [
          Expanded(
            child: SourceFaceCard(
              sourceEmotion: sourceEmotions[0],
              index: 0,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: SourceFaceCard(
              sourceEmotion: sourceEmotions[1],
              index: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Three faces - 2 top, 1 bottom centered
  Widget _buildThreeFaces() {
    return Padding(
      padding: EdgeInsets.all(spacing),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: SourceFaceCard(
                    sourceEmotion: sourceEmotions[0],
                    index: 0,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: SourceFaceCard(
                    sourceEmotion: sourceEmotions[1],
                    index: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing),
          Expanded(
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: SourceFaceCard(
                sourceEmotion: sourceEmotions[2],
                index: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Four faces - 2x2 grid
  Widget _buildFourFaces() {
    return Padding(
      padding: EdgeInsets.all(spacing),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: SourceFaceCard(
                    sourceEmotion: sourceEmotions[0],
                    index: 0,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: SourceFaceCard(
                    sourceEmotion: sourceEmotions[1],
                    index: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: SourceFaceCard(
                    sourceEmotion: sourceEmotions[2],
                    index: 2,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: SourceFaceCard(
                    sourceEmotion: sourceEmotions[3],
                    index: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Five faces - 3 top, 2 bottom
  Widget _buildFiveFaces() {
    return Padding(
      padding: EdgeInsets.all(spacing),
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(
                  child: SourceFaceCard(
                    sourceEmotion: sourceEmotions[0],
                    index: 0,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: SourceFaceCard(
                    sourceEmotion: sourceEmotions[1],
                    index: 1,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: SourceFaceCard(
                    sourceEmotion: sourceEmotions[2],
                    index: 2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SourceFaceCard(
                    sourceEmotion: sourceEmotions[3],
                    index: 3,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: SourceFaceCard(
                    sourceEmotion: sourceEmotions[4],
                    index: 4,
                  ),
                ),
                // Empty space to balance the 3-2 layout
                Expanded(child: SizedBox()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// More than 5 faces - scrollable grid
  Widget _buildMultipleFaces() {
    return GridView.builder(
      padding: EdgeInsets.all(spacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 0.75,
      ),
      itemCount: sourceEmotions.length,
      itemBuilder: (context, index) {
        return SourceFaceCard(
          sourceEmotion: sourceEmotions[index],
          index: index,
        );
      },
    );
  }
}

/// Loading skeleton for multi-face grid.
class MultiFaceGridSkeleton extends StatelessWidget {
  final int count;
  final double spacing;

  const MultiFaceGridSkeleton({
    super.key,
    this.count = 4,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(spacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 0.75,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        return _SkeletonCard(index: index);
      },
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  final int index;

  const _SkeletonCard({required this.index});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.0 + 2 * _controller.value, 0),
                end: Alignment(-0.5 + 2 * _controller.value, 0),
                colors: [
                  Colors.grey.shade900,
                  Colors.grey.shade800,
                  Colors.grey.shade900,
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Placeholder icon
                Center(
                  child: Icon(
                    Icons.face,
                    size: 48,
                    color: Colors.grey.shade700,
                  ),
                ),
                // Top-left badge skeleton
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 60,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // Bottom label skeleton
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
