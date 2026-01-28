import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sentiment_repository.dart';
import '../../domain/emotion_state.dart';

/// Debounce timer for source selection changes.
Timer? _debounceTimer;
Set<String>? _pendingSources;

class SourceChips extends ConsumerWidget {
  final EmotionState emotion;

  const SourceChips({super.key, required this.emotion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableSources = ref.watch(availableSourcesProvider);
    final selectedSources = ref.watch(selectedSourcesProvider);
    final contributions = emotion.sourceContributions ?? {};

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: availableSources.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final source = availableSources[index];
          final isSelected = selectedSources.contains(source.id);
          final contribution = contributions[source.id] ?? 0.0;
          final percentage = (contribution * 100).round();

          // Use short name for chips
          final shortName = source.id == 'hackernews' ? 'HN'
              : source.id == 'truthsocial' ? 'Truth'
              : source.id == 'bluesky' ? 'Bsky'
              : source.name;

          return FilterChip(
            avatar: Icon(
              source.icon,
              size: 14,
              color: isSelected ? Colors.white : source.color,
            ),
            label: Text(
              isSelected && percentage > 0 ? '$percentage%' : shortName,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
            selected: isSelected,
            selectedColor: source.color,
            backgroundColor: Colors.grey[200],
            showCheckmark: false,
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onSelected: (selected) {
              final current = ref.read(selectedSourcesProvider);
              final updated = Set<String>.from(current);

              if (selected) {
                updated.add(source.id);
              } else {
                // Prevent deselecting all sources
                if (updated.length > 1) {
                  updated.remove(source.id);
                }
              }

              // Debounce: wait 300ms before updating to batch rapid toggles
              _pendingSources = updated;
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                if (_pendingSources != null) {
                  ref.read(selectedSourcesProvider.notifier).state = _pendingSources!;
                  _pendingSources = null;
                }
              });
            },
          );
        },
      ),
    );
  }
}
