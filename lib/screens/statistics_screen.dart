/// Statistics Screen
///
/// A screen for displaying daily statistics including active time,
/// idle time, sleep time, average brightness, presence events, and
/// energy saving metrics with visual charts.
///
/// Purpose: Provide users with insights into system usage patterns
/// and energy efficiency through visual data representation.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_light/providers/system_provider.dart';
import 'package:smart_light/utils/constants.dart';
import 'package:fl_chart/fl_chart.dart';

/// Statistics Screen
///
/// Displays daily statistics with charts and progress indicators.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedTimeRange = 'day';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStatistics();
    });
  }

  Future<void> _refreshStatistics() async {
    final provider = Provider.of<SystemProvider>(context, listen: false);

    // Fetch historical data based on selected time range
    if (provider.useThingSpeak) {
      final results = _getResultsForTimeRange(_selectedTimeRange);
      await provider.refreshHistory(results: results);
    }

    // Reuse the selected range so the cards and charts describe the same
    // ThingSpeak history without making a duplicate request.
    await provider.refreshStatistics(fetchHistory: !provider.useThingSpeak);
  }

  int _getResultsForTimeRange(String range) {
    switch (range) {
      case 'hour':
        return 240; // ~1 hour at 15s intervals
      case 'day':
        return 5760; // ~24 hours at 15s intervals
      case 'week':
        return 40320; // ~7 days at 15s intervals
      default:
        return 100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStatistics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<SystemProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingStatistics) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final stats = provider.statistics;

          return RefreshIndicator(
            onRefresh: _refreshStatistics,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Range Selector
                  if (provider.useThingSpeak)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.date_range,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Time Range:',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            _TimeRangeChip(
                              label: 'Hour',
                              selected: _selectedTimeRange == 'hour',
                              onTap: () {
                                setState(() {
                                  _selectedTimeRange = 'hour';
                                });
                                _refreshStatistics();
                              },
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _TimeRangeChip(
                              label: 'Day',
                              selected: _selectedTimeRange == 'day',
                              onTap: () {
                                setState(() {
                                  _selectedTimeRange = 'day';
                                });
                                _refreshStatistics();
                              },
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _TimeRangeChip(
                              label: 'Week',
                              selected: _selectedTimeRange == 'week',
                              onTap: () {
                                setState(() {
                                  _selectedTimeRange = 'week';
                                });
                                _refreshStatistics();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (provider.useThingSpeak)
                    const SizedBox(height: AppSpacing.lg),

                  // Time Distribution Chart
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time Distribution Today',
                            style: AppTextStyles.headline3.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    value: (stats['active_time'] as num?)
                                            ?.toDouble() ??
                                        0.0,
                                    title: 'Active',
                                    color: AppColors.success,
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: (stats['idle_time'] as num?)
                                            ?.toDouble() ??
                                        0.0,
                                    title: 'Idle',
                                    color: AppColors.warning,
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: (stats['sleep_time'] as num?)
                                            ?.toDouble() ??
                                        0.0,
                                    title: 'Sleep',
                                    color: AppColors.primaryDark,
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Legend
                          _LegendItem(
                            color: AppColors.success,
                            label: 'Active Time',
                            value:
                                _formatDuration(stats['active_time'] as int?),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _LegendItem(
                            color: AppColors.warning,
                            label: 'Idle Time',
                            value: _formatDuration(stats['idle_time'] as int?),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _LegendItem(
                            color: AppColors.primaryDark,
                            label: 'Sleep Time',
                            value: _formatDuration(stats['sleep_time'] as int?),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Statistics Cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.3,
                    children: [
                      // Average Brightness
                      _StatCard(
                        icon: Icons.brightness_6,
                        label: 'Avg Brightness',
                        value:
                            '${(stats['avg_brightness'] as num?)?.toStringAsFixed(1) ?? '0.0'}%',
                        color: AppColors.accent,
                        progress:
                            (stats['avg_brightness'] as num?)?.toDouble() ??
                                0.0,
                        maxProgress: 100,
                      ),
                      // Presence Events
                      _StatCard(
                        icon: Icons.person,
                        label: 'Presence Events',
                        value: '${stats['presence_events'] as int? ?? 0}',
                        color: AppColors.primary,
                        progress:
                            (stats['presence_events'] as int?)?.toDouble() ??
                                0.0,
                        maxProgress: 100,
                        showProgress: false,
                      ),
                      // Energy Saving Time
                      _StatCard(
                        icon: Icons.eco,
                        label: 'Energy Saving',
                        value: _formatDuration(
                            stats['energy_saving_time'] as int?),
                        color: AppColors.success,
                        progress:
                            (stats['energy_saving_time'] as num?)?.toDouble() ??
                                0.0,
                        maxProgress: 86400, // 24 hours in seconds
                        showProgress: true,
                      ),
                      // Total Active Time
                      _StatCard(
                        icon: Icons.access_time,
                        label: 'Total Active',
                        value: _formatDuration(stats['active_time'] as int?),
                        color: AppColors.success,
                        progress:
                            (stats['active_time'] as num?)?.toDouble() ?? 0.0,
                        maxProgress: 86400,
                        showProgress: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Brightness Over Time Chart
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Brightness Trend',
                            style: AppTextStyles.headline3.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            height: 200,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 20,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: isDark
                                          ? AppColors.darkCardBackground
                                          : AppColors.cardBackground,
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() % 4 == 0) {
                                          return Text(
                                            '${value.toInt()}h',
                                            style:
                                                AppTextStyles.caption.copyWith(
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.textSecondary,
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 20,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '${value.toInt()}%',
                                          style: AppTextStyles.caption.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.textSecondary,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _generateBrightnessData(stats),
                                    isCurved: true,
                                    color: AppColors.accent,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: AppColors.accent
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                ],
                                minX: 0,
                                maxX: 24,
                                minY: 0,
                                maxY: 100,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Summary Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    color: isDark
                        ? AppColors.darkCardBackground
                        : AppColors.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Daily Summary',
                                style: AppTextStyles.headline3.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _SummaryRow(
                            label: 'Total Presence Events',
                            value: '${stats['presence_events'] as int? ?? 0}',
                          ),
                          const Divider(),
                          _SummaryRow(
                            label: 'Average Brightness',
                            value:
                                '${(stats['avg_brightness'] as num?)?.toStringAsFixed(1) ?? '0.0'}%',
                          ),
                          const Divider(),
                          _SummaryRow(
                            label: 'Energy Saving Time',
                            value: _formatDuration(
                                stats['energy_saving_time'] as int?),
                          ),
                          const Divider(),
                          _SummaryRow(
                            label: 'Efficiency Score',
                            value: '${_calculateEfficiency(stats)}%',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Format duration in seconds to human-readable format
  String _formatDuration(int? seconds) {
    if (seconds == null) return '0h 0m';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Generate sample brightness data for chart
  List<FlSpot> _generateBrightnessData(Map<String, dynamic> stats) {
    // In a real implementation, this would come from the ESP32
    // For now, generate sample data
    return [
      const FlSpot(0, 0),
      const FlSpot(4, 0),
      const FlSpot(6, 50),
      const FlSpot(8, 80),
      const FlSpot(12, 100),
      const FlSpot(14, 90),
      const FlSpot(18, 70),
      const FlSpot(20, 40),
      const FlSpot(22, 20),
      const FlSpot(24, 0),
    ];
  }

  /// Calculate efficiency score
  double _calculateEfficiency(Map<String, dynamic> stats) {
    final activeTime = (stats['active_time'] as num?)?.toDouble() ?? 0.0;
    final energySavingTime =
        (stats['energy_saving_time'] as num?)?.toDouble() ?? 0.0;
    final totalTime = activeTime + energySavingTime;

    if (totalTime == 0) return 0.0;

    return ((energySavingTime / totalTime) * 100).clamp(0, 100);
  }
}

/// Legend Item
///
/// Internal widget for chart legend items.
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Stat Card
///
/// Internal widget for statistics cards with progress indicators.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double progress;
  final double maxProgress;
  final bool showProgress;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.progress,
    required this.maxProgress,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressValue =
        showProgress ? (progress / maxProgress).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const Spacer(),
                if (showProgress)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.sm,
                      ),
                    ),
                    child: Text(
                      '${(progressValue * 100).toInt()}%',
                      style: AppTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTextStyles.headline3.copyWith(
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showProgress) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: isDark
                      ? AppColors.darkCardBackground
                      : AppColors.cardBackground,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Summary Row
///
/// Internal widget for summary information rows.
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Time Range Chip
///
/// Internal widget for time range selection chips.
class _TimeRangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TimeRangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark
                  ? AppColors.darkCardBackground
                  : AppColors.cardBackground),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
