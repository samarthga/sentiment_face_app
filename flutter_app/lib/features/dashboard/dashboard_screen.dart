import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../face/data/sentiment_repository.dart';

/// Provider for emotion topics mapping.
final emotionTopicsProvider = FutureProvider.autoDispose<Map<String, List<String>>>((ref) async {
  final repository = ref.watch(sentimentRepositoryProvider);
  return repository.getEmotionTopics();
});


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _searchTimer;

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  void _startSearchPolling(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final searchQuery = ref.read(globalSearchQueryProvider);
      if (searchQuery != null && searchQuery.isNotEmpty) {
        ref.invalidate(globalSearchResultProvider);
        ref.invalidate(emotionStateProvider);
      }
    });
  }

  void _stopSearchPolling() {
    _searchTimer?.cancel();
    _searchTimer = null;
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();

        void doSearch() {
          final query = controller.text.trim();
          if (query.isNotEmpty) {
            Navigator.of(dialogContext).pop();
            _executeSearch(query);
          }
        }

        return AlertDialog(
          title: const Text('Search Topic'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter topic (e.g., AI, Bitcoin, Climate)...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => doSearch(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: doSearch,
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _executeSearch(String query) async {
    // Set global search query - this triggers globalSearchResultProvider
    ref.read(globalSearchQueryProvider.notifier).state = query;

    // Start polling for this search
    _startSearchPolling(query);

    // Refresh topics
    ref.invalidate(emotionTopicsProvider);
  }

  void _clearSearch() async {
    _stopSearchPolling();
    ref.read(globalSearchQueryProvider.notifier).state = null;

    // Clear on backend too
    final repository = ref.read(sentimentRepositoryProvider);
    await repository.clearSearch();

    // Refresh normal data
    ref.invalidate(emotionStateProvider);
    ref.invalidate(emotionTopicsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final emotionAsync = ref.watch(emotionStateProvider);
    final emotionTopicsAsync = ref.watch(emotionTopicsProvider);
    final searchQuery = ref.watch(globalSearchQueryProvider);
    final isSearching = searchQuery != null && searchQuery.isNotEmpty;

    // Watch global search results if searching
    final searchResultAsync = isSearching
        ? ref.watch(globalSearchResultProvider)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? Row(
                children: [
                  const Icon(Icons.search, size: 20),
                  const SizedBox(width: 8),
                  Text('"$searchQuery"'),
                ],
              )
            : const Text('Dashboard'),
        actions: [
          if (isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear search',
              onPressed: _clearSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search topic',
              onPressed: _showSearchDialog,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (isSearching) {
                ref.invalidate(globalSearchResultProvider);
              }
              ref.invalidate(emotionStateProvider);
              ref.invalidate(emotionTopicsProvider);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: emotionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (defaultEmotion) {
            final emotionTopics = emotionTopicsAsync.valueOrNull ?? {};

            // Use search-specific emotions when searching
            final searchResult = searchResultAsync?.valueOrNull;
            final searchEmotion = searchResult?.emotion;

            // Helper to get emotion value (from search or default)
            double getEmotionValue(String key, double defaultValue) {
              if (isSearching && searchEmotion != null) {
                return (searchEmotion[key] as num?)?.toDouble() ?? defaultValue;
              }
              return defaultValue;
            }

            // Get the actual values to display
            final happiness = getEmotionValue('happiness', defaultEmotion.happiness);
            final sadness = getEmotionValue('sadness', defaultEmotion.sadness);
            final anger = getEmotionValue('anger', defaultEmotion.anger);
            final fear = getEmotionValue('fear', defaultEmotion.fear);
            final surprise = getEmotionValue('surprise', defaultEmotion.surprise);
            final disgust = getEmotionValue('disgust', defaultEmotion.disgust);
            final confusion = getEmotionValue('confusion', defaultEmotion.confusion);
            final pride = getEmotionValue('pride', defaultEmotion.pride);
            final overallSentiment = getEmotionValue('overall_sentiment', defaultEmotion.overallSentiment);
            final intensity = getEmotionValue('intensity', defaultEmotion.intensity);

            // Calculate dominant emotion for search results
            String dominantEmotion = defaultEmotion.dominantEmotion;
            double dominantIntensity = defaultEmotion.dominantIntensity;
            if (isSearching && searchEmotion != null) {
              final emotions = {
                'happiness': happiness,
                'sadness': sadness,
                'anger': anger,
                'fear': fear,
                'surprise': surprise,
                'disgust': disgust,
              };
              final sorted = emotions.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              dominantEmotion = sorted.first.key;
              dominantIntensity = sorted.first.value;
            }

            return ListView(
              children: [
                // Search indicator
                if (isSearching) ...[
                  _SearchIndicator(
                    query: searchQuery,
                    resultAsync: searchResultAsync,
                    onClear: _clearSearch,
                  ),
                  const SizedBox(height: 16),
                ],

                _StatCard(
                  title: isSearching ? 'Topic Sentiment' : 'Overall Sentiment',
                  value: '${(overallSentiment * 100).toStringAsFixed(1)}%',
                  subtitle: overallSentiment > 0 ? 'Positive' : 'Negative',
                  icon: overallSentiment > 0
                      ? Icons.sentiment_satisfied
                      : Icons.sentiment_dissatisfied,
                  color: overallSentiment > 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),
                _StatCard(
                  title: 'Dominant Emotion',
                  value: dominantEmotion.toUpperCase(),
                  subtitle: '${(dominantIntensity * 100).toStringAsFixed(0)}% intensity',
                  icon: Icons.psychology,
                  color: Colors.purple,
                  topics: isSearching ? [searchQuery] : emotionTopics[dominantEmotion.toLowerCase()],
                ),
                const SizedBox(height: 16),
                _StatCard(
                  title: 'Expression Intensity',
                  value: '${(intensity * 100).toStringAsFixed(0)}%',
                  subtitle: 'How strongly emotions are being expressed',
                  icon: Icons.speed,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      isSearching ? 'Emotions for "$searchQuery"' : 'Emotion Breakdown',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    if (!isSearching)
                      TextButton.icon(
                        onPressed: _showSearchDialog,
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Search'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _EmotionRow(
                  label: 'Happiness',
                  value: happiness,
                  topics: isSearching ? null : emotionTopics['happiness'],
                ),
                _EmotionRow(
                  label: 'Sadness',
                  value: sadness,
                  topics: isSearching ? null : emotionTopics['sadness'],
                ),
                _EmotionRow(
                  label: 'Anger',
                  value: anger,
                  topics: isSearching ? null : emotionTopics['anger'],
                ),
                _EmotionRow(
                  label: 'Fear',
                  value: fear,
                  topics: isSearching ? null : emotionTopics['fear'],
                ),
                _EmotionRow(
                  label: 'Surprise',
                  value: surprise,
                  topics: isSearching ? null : emotionTopics['surprise'],
                ),
                _EmotionRow(
                  label: 'Disgust',
                  value: disgust,
                  topics: isSearching ? null : emotionTopics['disgust'],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchIndicator extends StatelessWidget {
  final String query;
  final AsyncValue<SearchResult?>? resultAsync;
  final VoidCallback onClear;

  const _SearchIndicator({
    required this.query,
    required this.resultAsync,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Searching: "$query"',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                if (resultAsync?.isLoading ?? false)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (resultAsync != null)
              resultAsync!.when(
                data: (result) {
                  if (result == null) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Found ${result.count} articles • Auto-refreshing every 30s',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Searching news sources...',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String>? topics;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.topics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  if (topics != null && topics!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '[${topics!.take(3).join(", ")}]',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmotionRow extends StatelessWidget {
  final String label;
  final double value;
  final List<String>? topics;

  const _EmotionRow({
    required this.label,
    required this.value,
    this.topics,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getEmotionColor(label);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(label),
                    if (topics != null && topics!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '[${topics!.take(3).join(", ")}]',
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text('${(value * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ],
      ),
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happiness':
        return Colors.amber;
      case 'sadness':
        return Colors.blue;
      case 'anger':
        return Colors.red;
      case 'fear':
        return Colors.purple;
      case 'surprise':
        return Colors.orange;
      case 'disgust':
        return Colors.green;
      case 'confusion':
        return Colors.teal;
      case 'pride':
        return Colors.amber.shade700;
      case 'loneliness':
        return Colors.indigo;
      case 'pain':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }
}
