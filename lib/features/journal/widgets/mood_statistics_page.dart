import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/storage/entry_repository.dart';
import '../../../shared/widgets/frosted_card.dart';
import '../../../core/theme/theme_provider.dart';
import 'package:stargazer/core/theme/app_theme.dart';

/// 情绪统计页面
///
/// 展示用户的情绪分布和趋势：
/// - 情绪饼图（总体分布）
/// - 月度情绪曲线
/// - 年度情绪统计
class MoodStatisticsPage extends ConsumerWidget {
  const MoodStatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('情绪统计'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 情绪分布饼图 ──────────────────────────
          const Text(
            '情绪分布',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FrostedCard(
            effect: theme.glassEffect,
            child: SizedBox(
              height: 250,
              child: FutureBuilder<Map<String, int>>(
                future: _getMoodDistribution(ref),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final moodData = snapshot.data ?? {};

                  if (moodData.isEmpty) {
                    return const Center(
                      child: Text(
                        '暂无情绪数据',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return PieChart(
                    PieChartData(
                      sections: _buildPieSections(moodData, theme),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ─── 月度情绪趋势 ──────────────────────────
          const Text(
            '月度情绪趋势',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FrostedCard(
            effect: theme.glassEffect,
            child: SizedBox(
              height: 200,
              child: FutureBuilder<List<MoodTrendData>>(
                future: _getMonthlyMoodTrend(ref),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final trendData = snapshot.data ?? [];

                  if (trendData.isEmpty) {
                    return const Center(
                      child: Text(
                        '暂无趋势数据',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < trendData.length) {
                                return Text(
                                  '${trendData[index].month}月',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: trendData
                              .asMap()
                              .entries
                              .map((entry) => FlSpot(
                                    entry.key.toDouble(),
                                    entry.value.moodScore,
                                  ))
                              .toList(),
                          isCurved: true,
                          color: theme.diaryColor.color,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: theme.diaryColor.color.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ─── 统计卡片 ──────────────────────────────
          const Text(
            '统计数据',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<StatsData>(
            future: _getStatsData(ref),
            builder: (context, snapshot) {
              final stats = snapshot.data;
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '总日记数',
                      stats?.totalEntries.toString() ?? '-',
                      Icons.menu_book,
                      theme.diaryColor.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '平均情绪',
                      stats?.averageMood ?? '-',
                      Icons.mood,
                      theme.todoColor.color,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    Map<String, int> moodData,
    StarfieldTheme theme,
  ) {
    final colors = {
      '😊': theme.diaryColor.color,
      '😐': Colors.grey,
      '😢': Colors.blue,
      '😡': Colors.red,
      '🤔': Colors.purple,
      '🥰': Colors.pink,
      '😎': Colors.orange,
    };

    final total = moodData.values.fold(0, (sum, count) => sum + count);

    return moodData.entries.map((entry) {
      final percentage = (entry.value / total * 100).round();
      return PieChartSectionData(
        color: colors[entry.key] ?? Colors.grey,
        value: entry.value.toDouble(),
        title: '$percentage%',
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Future<Map<String, int>> _getMoodDistribution(WidgetRef ref) async {
    final repo = ref.read(entryRepositoryProvider);
    final entries = await repo.getAllEntries();

    final moodCount = <String, int>{};
    for (final entry in entries) {
      if (entry.mood != null && entry.mood!.isNotEmpty) {
        moodCount[entry.mood!] = (moodCount[entry.mood!] ?? 0) + 1;
      }
    }

    return moodCount;
  }

  Future<List<MoodTrendData>> _getMonthlyMoodTrend(WidgetRef ref) async {
    final repo = ref.read(entryRepositoryProvider);
    final entries = await repo.getAllEntries();

    // 按月份分组
    final monthlyData = <String, List<int>>{};
    for (final entry in entries) {
      if (entry.mood != null && entry.mood!.isNotEmpty) {
        final key = '${entry.createdAt.year}-${entry.createdAt.month}';
        monthlyData.putIfAbsent(key, () => []);
        monthlyData[key]!.add(_moodToScore(entry.mood!));
      }
    }

    // 计算每月平均情绪分数
    final trendData = <MoodTrendData>[];
    final sortedKeys = monthlyData.keys.toList()..sort();

    for (final key in sortedKeys) {
      final scores = monthlyData[key]!;
      final average = scores.reduce((a, b) => a + b) / scores.length;
      final parts = key.split('-');
      trendData.add(MoodTrendData(
        month: int.parse(parts[1]),
        moodScore: average,
      ));
    }

    return trendData;
  }

  Future<StatsData> _getStatsData(WidgetRef ref) async {
    final repo = ref.read(entryRepositoryProvider);
    final entries = await repo.getAllEntries();

    int totalEntries = entries.length;
    int totalMoodScore = 0;
    int moodCount = 0;

    for (final entry in entries) {
      if (entry.mood != null && entry.mood!.isNotEmpty) {
        totalMoodScore += _moodToScore(entry.mood!);
        moodCount++;
      }
    }

    final averageMood = moodCount > 0
        ? _scoreToMood(totalMoodScore / moodCount)
        : '-';

    return StatsData(
      totalEntries: totalEntries,
      averageMood: averageMood,
    );
  }

  int _moodToScore(String mood) {
    switch (mood) {
      case '😊':
      case '🥰':
        return 5;
      case '😎':
        return 4;
      case '😐':
      case '':
        return 3;
      case '😢':
        return 2;
      case '😡':
        return 1;
      default:
        return 3;
    }
  }

  String _scoreToMood(double score) {
    if (score >= 4.5) return '😊';
    if (score >= 3.5) return '😎';
    if (score >= 2.5) return '';
    if (score >= 1.5) return '😢';
    return '😡';
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return FrostedCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class MoodTrendData {
  final int month;
  final double moodScore;

  MoodTrendData({
    required this.month,
    required this.moodScore,
  });
}

class StatsData {
  final int totalEntries;
  final String averageMood;

  StatsData({
    required this.totalEntries,
    required this.averageMood,
  });
}
