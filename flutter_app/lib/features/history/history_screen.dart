import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../face/data/sentiment_repository.dart';

/// Provider for history data.
final historyProvider = FutureProvider.autoDispose<HistoryResponse>((ref) async {
  final repository = ref.watch(sentimentRepositoryProvider);
  return repository.getHistory(limit: 100);
});

/// Provider for trending topics.
final trendingTopicsProvider = FutureProvider.autoDispose<List<TopicData>>((ref) async {
  final repository = ref.watch(sentimentRepositoryProvider);
  return repository.getTrendingTopics(hours: 1, limit: 10);
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final topicsAsync = ref.watch(trendingTopicsProvider);
    // Use global search query for consistency across pages
    final selectedTopic = ref.watch(globalSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: selectedTopic != null && selectedTopic.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '"$selectedTopic"',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : const Text('Sentiment History'),
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search topic',
            onPressed: () => _showSearchDialog(context, ref),
          ),
          if (selectedTopic != null && selectedTopic.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear search',
              onPressed: () {
                ref.read(globalSearchQueryProvider.notifier).state = null;
                // Clear on backend too (fire and forget)
                ref.read(sentimentRepositoryProvider).clearSearch();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(historyProvider);
              ref.invalidate(trendingTopicsProvider);
              if (selectedTopic != null && selectedTopic.isNotEmpty) {
                ref.invalidate(globalSearchResultProvider);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(historyProvider);
          ref.invalidate(trendingTopicsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emotion Trend Chart (shown when topic is selected)
              if (selectedTopic != null)
                historyAsync.when(
                  data: (response) => _buildTrendChart(context, ref, response.data, selectedTopic),
                  loading: () => const SizedBox(
                    height: 250,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => _buildErrorCard('Failed to load chart'),
                ),

              // Trending Topics Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Trending Topics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showSearchDialog(context, ref),
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Search'),
                    ),
                  ],
                ),
              ),
              topicsAsync.when(
                data: (topics) => _buildTopicsSection(context, ref, topics, selectedTopic),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => _buildErrorCard('Failed to load topics'),
              ),

              const Divider(height: 32),

              // Topic Trend Lines Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Topic Trends',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Show trend lines for each trending topic
              topicsAsync.when(
                data: (topics) => historyAsync.when(
                  data: (response) => _buildTopicTrendLines(context, ref, response.data, topics),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => _buildErrorCard('Failed to load trends'),
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => _buildErrorCard('Failed to load topics'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        void executeSearch(String query) {
          final trimmed = query.trim().toLowerCase();
          if (trimmed.isEmpty) return;

          Navigator.of(dialogContext).pop();

          // Set global search query - triggers backend search across all pages
          ref.read(globalSearchQueryProvider.notifier).state = trimmed;
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
            onSubmitted: (value) => executeSearch(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => executeSearch(controller.text),
              child: const Text('Search'),
            ),
          ],
        );
      },
    ).then((_) => controller.dispose());
  }

  Widget _buildTrendChart(BuildContext context, WidgetRef ref, List<HistoryEntry> entries, String topic) {
    // Filter entries that contain this topic and get emotion data
    final topicEntries = entries.where((entry) {
      return entry.topics.any((t) => t.topic.toLowerCase() == topic.toLowerCase());
    }).toList();

    if (topicEntries.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No data available for this topic'),
        ),
      );
    }

    // Reverse to get chronological order (oldest first)
    final chronological = topicEntries.reversed.toList();

    // Get the dominant emotion for this topic
    final emotionCounts = <String, int>{};
    for (final entry in chronological) {
      emotionCounts[entry.dominantEmotion] = (emotionCounts[entry.dominantEmotion] ?? 0) + 1;
    }
    final dominantEmotion = emotionCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    // Prepare chart data - show the dominant emotion's values over time
    final spots = <FlSpot>[];
    for (int i = 0; i < chronological.length; i++) {
      final entry = chronological[i];
      final value = entry.emotions[dominantEmotion] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    final emotionColor = _getEmotionColor(dominantEmotion);

    return Container(
      key: ValueKey('main_trend_$topic'),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: emotionColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: emotionColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: emotionColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart, size: 16, color: emotionColor),
                    const SizedBox(width: 4),
                    Text(
                      topic.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: emotionColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: emotionColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _capitalizeFirst(dominantEmotion),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${chronological.length} data points',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 0.2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value * 100).toInt()}%',
                          style: TextStyle(color: Colors.grey[600], fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (chronological.length / 4).ceilToDouble().clamp(1, double.infinity),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < chronological.length) {
                          final time = DateFormat('HH:mm').format(chronological[index].timestamp);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              time,
                              style: TextStyle(color: Colors.grey[600], fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (chronological.length - 1).toDouble(),
                minY: 0,
                maxY: 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: emotionColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: emotionColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: emotionColor.withOpacity(0.2),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= 0 && index < chronological.length) {
                          final entry = chronological[index];
                          final time = DateFormat('HH:mm').format(entry.timestamp);
                          return LineTooltipItem(
                            '${(spot.y * 100).toInt()}%\n$time',
                            TextStyle(
                              color: emotionColor,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),

          // Legend
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: emotionColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_capitalizeFirst(dominantEmotion)} intensity for "$topic" over time',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicTrendLines(BuildContext context, WidgetRef ref, List<HistoryEntry> entries, List<TopicData> topics) {
    if (topics.isEmpty || entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No topic trends available yet',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Build a compact trend line for each topic (top 6)
    return Column(
      children: topics.take(6).map((topic) {
        return _buildCompactTrendLine(context, entries, topic);
      }).toList(),
    );
  }

  Widget _buildCompactTrendLine(BuildContext context, List<HistoryEntry> entries, TopicData topic) {
    // Filter entries that contain this topic
    final topicEntries = entries.where((entry) {
      return entry.topics.any((t) => t.topic.toLowerCase() == topic.topic.toLowerCase());
    }).toList();

    if (topicEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Reverse to get chronological order (oldest first)
    final chronological = topicEntries.reversed.toList();

    // Get the dominant emotion for this topic
    final emotionCounts = <String, int>{};
    for (final entry in chronological) {
      emotionCounts[entry.dominantEmotion] = (emotionCounts[entry.dominantEmotion] ?? 0) + 1;
    }
    final dominantEmotion = emotionCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final emotionColor = _getEmotionColor(dominantEmotion);

    // Prepare chart data
    final spots = <FlSpot>[];
    for (int i = 0; i < chronological.length; i++) {
      final entry = chronological[i];
      final value = entry.emotions[dominantEmotion] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    return Container(
      key: ValueKey('trend_${topic.topic}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: emotionColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: emotionColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with topic name and emotion
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: emotionColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  topic.topic.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: emotionColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _capitalizeFirst(dominantEmotion),
                  style: TextStyle(
                    color: emotionColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${chronological.length} points',
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Compact chart
          SizedBox(
            height: 60,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (chronological.length - 1).toDouble().clamp(1, double.infinity),
                minY: 0,
                maxY: 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: emotionColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: emotionColor.withOpacity(0.2),
                    ),
                  ),
                ],
                lineTouchData: const LineTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsSection(BuildContext context, WidgetRef ref, List<TopicData> topics, String? selectedTopic) {
    if (topics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No trending topics yet. Data will appear after a few sentiment updates.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: topics.map((topic) {
          final sentiment = topic.avgSentiment ?? topic.sentiment;
          final color = _getSentimentColor(sentiment);
          final mentions = topic.mentions ?? topic.count;
          final isSelected = selectedTopic?.toLowerCase() == topic.topic.toLowerCase();
          final emotionColor = topic.dominantEmotion != null
              ? _getEmotionColor(topic.dominantEmotion!)
              : color;

          return ActionChip(
            key: ValueKey('topic_${topic.topic}'),
            avatar: CircleAvatar(
              backgroundColor: isSelected ? Colors.white : emotionColor,
              radius: 12,
              child: Text(
                '$mentions',
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? emotionColor : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            label: Text(
              topic.topic,
              style: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
            backgroundColor: isSelected ? emotionColor : emotionColor.withOpacity(0.1),
            side: BorderSide(color: emotionColor, width: isSelected ? 2 : 1),
            onPressed: () {
              if (isSelected) {
                ref.read(globalSearchQueryProvider.notifier).state = null;
              } else {
                ref.read(globalSearchQueryProvider.notifier).state = topic.topic;
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, WidgetRef ref, List<HistoryEntry> entries, String? selectedTopic) {
    // Filter entries by selected topic
    final filteredEntries = selectedTopic == null
        ? entries
        : entries.where((entry) {
            return entry.topics.any((t) => t.topic.toLowerCase() == selectedTopic.toLowerCase());
          }).toList();

    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No history data yet',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'History will appear after sentiment analysis runs',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (filteredEntries.isEmpty && selectedTopic != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.filter_list_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No entries found for "$selectedTopic"',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(globalSearchQueryProvider.notifier).state = null;
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear filter'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = filteredEntries[index];
        return _buildHistoryCard(
          context,
          ref,
          entry,
          selectedTopic,
          key: ValueKey('history_card_${entry.timestamp.millisecondsSinceEpoch}'),
        );
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context, WidgetRef ref, HistoryEntry entry, String? selectedTopic, {Key? key}) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('MMM d');
    final sentiment = entry.overallSentiment;
    final color = _getSentimentColor(sentiment);

    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with time and dominant emotion
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getEmotionColor(entry.dominantEmotion).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _capitalizeFirst(entry.dominantEmotion),
                    style: TextStyle(
                      color: _getEmotionColor(entry.dominantEmotion),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${dateFormat.format(entry.timestamp)} ${timeFormat.format(entry.timestamp)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Emotion bars
            _buildEmotionBars(entry.emotions),

            // Topics
            if (entry.topics.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: entry.topics.take(5).map((topic) {
                  final isHighlighted = selectedTopic != null &&
                      topic.topic.toLowerCase() == selectedTopic.toLowerCase();
                  final topicColor = _getSentimentColor(topic.sentiment);

                  return GestureDetector(
                    key: ValueKey('history_topic_${entry.timestamp.millisecondsSinceEpoch}_${topic.topic}'),
                    onTap: () {
                      ref.read(globalSearchQueryProvider.notifier).state = topic.topic;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isHighlighted ? topicColor : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: isHighlighted ? Border.all(color: topicColor, width: 2) : null,
                      ),
                      child: Text(
                        topic.topic,
                        style: TextStyle(
                          fontSize: 11,
                          color: isHighlighted ? Colors.white : null,
                          fontWeight: isHighlighted ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionBars(Map<String, double> emotions) {
    // Only show basic emotions (exclude derived: confusion, pride, loneliness, pain)
    const basicEmotions = {'happiness', 'sadness', 'anger', 'fear', 'surprise', 'disgust'};
    final filtered = emotions.entries.where((e) => basicEmotions.contains(e.key)).toList();

    // Sort by value descending and take top 3
    final sorted = filtered..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).toList();

    return Row(
      children: top3.map((e) {
        final color = _getEmotionColor(e.key);
        final percentage = (e.value * 100).toInt();

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_capitalizeFirst(e.key)} $percentage%',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                LinearProgressIndicator(
                  value: e.value,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 4,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorCard(String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSentimentColor(double sentiment) {
    if (sentiment > 0.2) return Colors.green;
    if (sentiment < -0.2) return Colors.red;
    return Colors.orange;
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

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
