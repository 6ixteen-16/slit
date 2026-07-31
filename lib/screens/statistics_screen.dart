/// Statistics Screen
///
/// A screen for displaying daily statistics including active time,
/// idle time, sleep time, average brightness, presence events, and
/// energy saving metrics with visual charts.
///
/// Purpose: Provide users with insights into system usage patterns
/// and energy efficiency through visual data representation.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_light/providers/system_provider.dart';
import 'package:smart_light/utils/constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            child: AppBar(
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
          ),
        ),
      ),
      body: Consumer<SystemProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingStatistics && provider.statistics.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final stats = provider.statistics;
          final feeds = provider.thingSpeakHistory?.feeds ?? const [];

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
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            Icon(
                              Icons.date_range,
                              color: isDark ? AppColors.secondary : AppColors.primary,
                            ),
                            Text(
                              'Time Range:',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
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
                            _TimeRangeChip(
                              label: 'Day',
                              selected: _selectedTimeRange == 'day',
                              onTap: () {
                                setState(() => _selectedTimeRange = 'day');
                                _refreshStatistics();
                              },
                            ),
                            _TimeRangeChip(
                              label: 'Week',
                              selected: _selectedTimeRange == 'week',
                              onTap: () {
                                setState(() => _selectedTimeRange = 'week');
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
                            'Time Distribution (${_selectedTimeRange.substring(0, 1).toUpperCase()}${_selectedTimeRange.substring(1)})',
                            style: AppTextStyles.headline3.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if ((stats['active_time'] as num? ?? 0) == 0 &&
                              (stats['idle_time'] as num? ?? 0) == 0 &&
                              (stats['sleep_time'] as num? ?? 0) == 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                              child: Center(
                                child: Text(
                                  'No data available for this time range.',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else ...[
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
                                      color: AppColors.secondary,
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
                              color: AppColors.secondary,
                              label: 'Sleep Time',
                              value: _formatDuration(stats['sleep_time'] as int?),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Statistics Cards
                  Builder(builder: (context) {
                    double maxSeconds = 86400; // Day
                    if (_selectedTimeRange == 'hour') {
                      maxSeconds = 3600;
                    } else if (_selectedTimeRange == 'week') {
                      maxSeconds = 604800;
                    }

                    final energySavingTime =
                        (stats['energy_saving_time'] as num?)?.toDouble() ?? 0.0;
                    // Assuming 15W bulb
                    final energySavedWh = (energySavingTime / 3600.0) * 15.0;
                    final maxEnergySavedWh = (maxSeconds / 3600.0) * 15.0;
                    
                    return GridView.count(
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
                          color: isDark ? AppColors.secondary : AppColors.primary,
                          progress:
                              (stats['presence_events'] as int?)?.toDouble() ??
                                  0.0,
                          maxProgress: 100,
                          showProgress: false,
                        ),
                        // Energy Saved
                        _StatCard(
                          icon: Icons.eco,
                          label: 'Energy Saved',
                          value: '${energySavedWh.toStringAsFixed(1)} Wh',
                          color: AppColors.success,
                          progress: energySavedWh,
                          maxProgress: maxEnergySavedWh > 0 ? maxEnergySavedWh : 1,
                          showProgress: true,
                        ),
                        // Total Active Time -> Active Time
                        _StatCard(
                          icon: Icons.access_time,
                          label: 'Active Time',
                          value: _formatDuration(stats['active_time'] as int?),
                          color: AppColors.success,
                          progress:
                              (stats['active_time'] as num?)?.toDouble() ?? 0.0,
                          maxProgress: maxSeconds,
                          showProgress: true,
                        ),
                      ],
                    );
                  }),
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
                            _brightnessTrendTitle(_selectedTimeRange),
                            style: AppTextStyles.headline3.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _brightnessTrendSubtitle(_selectedTimeRange),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (feeds.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                              child: Center(
                                child: Text(
                                  'No brightness data for this time range.',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                          SizedBox(
                            height: 220,
                            child: Builder(builder: (context) {
                              final spots = _buildBrightnessSpots(feeds);
                              double maxX = spots.isNotEmpty ? spots.last.x : 1.0;
                              final minX = spots.isNotEmpty ? spots.first.x : 0.0;
                              if (maxX == minX) maxX += 1.0;
                              final xInterval = _xInterval(_selectedTimeRange);
                              return LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    horizontalInterval: 20,
                                    verticalInterval: xInterval,
                                    getDrawingHorizontalLine: (_) => FlLine(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black12,
                                      strokeWidth: 1,
                                    ),
                                    getDrawingVerticalLine: (_) => FlLine(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black12,
                                      strokeWidth: 1,
                                    ),
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
                                        interval: xInterval,
                                        reservedSize: 42,
                                        getTitlesWidget: (value, meta) {
                                          // Skip the very first and very last to
                                          // avoid clipping at chart boundaries
                                          if (value == meta.min || value == meta.max) {
                                            return const SizedBox.shrink();
                                          }
                                          final label = _formatXLabel(
                                            value,
                                            maxX,
                                            _selectedTimeRange,
                                          );
                                          if (label.isEmpty) return const SizedBox.shrink();
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            angle: -0.7,
                                            space: 4,
                                            child: Text(
                                              label,
                                              style: AppTextStyles.caption.copyWith(
                                                fontSize: 9,
                                                color: isDark
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      axisNameWidget: Padding(
                                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                                        child: Text(
                                          'Brightness (%)',
                                          style: AppTextStyles.caption.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      axisNameSize: 20,
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 20,
                                        reservedSize: 36,
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
                                      spots: spots,
                                      isCurved: true,
                                      color: AppColors.accent,
                                      barWidth: 2.5,
                                      dotData: FlDotData(
                                        show: spots.length < 30,
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: AppColors.accent.withValues(alpha: 0.15),
                                      ),
                                    ),
                                  ],
                                  minX: minX,
                                  maxX: maxX,
                                  minY: 0,
                                  maxY: 100,
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((spot) {
                                          final dt = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                                          return LineTooltipItem(
                                            '${DateFormat('HH:mm').format(dt)}\n${spot.y.toStringAsFixed(0)}%',
                                            const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                   const SizedBox(height: AppSpacing.lg),

                   // Ambient Light Over Time
                   if (feeds.isNotEmpty)
                     Builder(builder: (context) {
                       final ambSpots = _buildAmbientLightSpots(feeds);
                       if (ambSpots.isEmpty) return const SizedBox.shrink();
                       double maxAmbX = ambSpots.last.x;
                       final minAmbX = ambSpots.first.x;
                       if (maxAmbX == minAmbX) maxAmbX += 1.0;
                       final maxAmbY = ambSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
                       final yMax = maxAmbY < 10 ? 10.0 : (maxAmbY * 1.2);
                       final xIntvl = _xInterval(_selectedTimeRange);
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
                               Text(
                                 'Ambient Light (lux)',
                                 style: AppTextStyles.headline3.copyWith(
                                   color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                 ),
                               ),
                               Text(
                                 'How bright the room was over time',
                                 style: AppTextStyles.bodySmall.copyWith(
                                   color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                                       getDrawingHorizontalLine: (_) => FlLine(
                                         color: isDark ? Colors.white10 : Colors.black12,
                                         strokeWidth: 1,
                                       ),
                                     ),
                                     titlesData: FlTitlesData(
                                       rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                       topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                       bottomTitles: AxisTitles(
                                         sideTitles: SideTitles(
                                           showTitles: true,
                                           interval: xIntvl,
                                           reservedSize: 42,
                                           getTitlesWidget: (value, meta) {
                                             if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                                             final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                             return SideTitleWidget(
                                               axisSide: meta.axisSide,
                                               angle: -0.7,
                                               space: 4,
                                               child: Text(
                                                 DateFormat('HH:mm').format(dt),
                                                 style: AppTextStyles.caption.copyWith(
                                                   fontSize: 9,
                                                   color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                                 ),
                                               ),
                                             );
                                           },
                                         ),
                                       ),
                                       leftTitles: AxisTitles(
                                         sideTitles: SideTitles(
                                           showTitles: true,
                                           reservedSize: 44,
                                           getTitlesWidget: (value, meta) {
                                             return Text(
                                               '${value.toInt()}lx',
                                               style: AppTextStyles.caption.copyWith(
                                                 fontSize: 9,
                                                 color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                               ),
                                             );
                                           },
                                         ),
                                       ),
                                     ),
                                     borderData: FlBorderData(show: false),
                                     lineBarsData: [
                                       LineChartBarData(
                                         spots: ambSpots,
                                         isCurved: true,
                                         color: AppColors.warning,
                                         barWidth: 2.5,
                                         dotData: const FlDotData(show: false),
                                         belowBarData: BarAreaData(
                                           show: true,
                                           color: AppColors.warning.withValues(alpha: 0.12),
                                         ),
                                       ),
                                     ],
                                     minX: minAmbX,
                                     maxX: maxAmbX,
                                     minY: 0,
                                     maxY: yMax,
                                     lineTouchData: LineTouchData(
                                       touchTooltipData: LineTouchTooltipData(
                                         getTooltipItems: (spots) => spots.map((s) {
                                           final dt = DateTime.fromMillisecondsSinceEpoch(s.x.toInt());
                                           return LineTooltipItem(
                                             '${DateFormat('HH:mm').format(dt)}\n${s.y.toStringAsFixed(1)} lux',
                                             const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                           );
                                         }).toList(),
                                       ),
                                     ),
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ),
                       );
                     }),
                   const SizedBox(height: AppSpacing.lg),

                   // Presence Activity Timeline
                   if (feeds.isNotEmpty)
                     _PresenceTimeline(
                       feeds: feeds,
                       isDark: isDark,
                     ),
                   if (feeds.isNotEmpty)
                     const SizedBox(height: AppSpacing.lg),

                  // Summary Card - dynamic with time range
                  Builder(builder: (context) {
                    double maxSeconds = 86400;
                    if (_selectedTimeRange == 'hour') maxSeconds = 3600;
                    if (_selectedTimeRange == 'week') maxSeconds = 604800;
                    final energySavingTime =
                        (stats['energy_saving_time'] as num?)?.toDouble() ?? 0.0;
                    final energySavedWh = (energySavingTime / 3600.0) * 15.0;
                    final activeTime = (stats['active_time'] as num?)?.toDouble() ?? 0.0;
                    final efficiency = maxSeconds > 0
                        ? ((energySavingTime / maxSeconds) * 100).clamp(0, 100)
                        : 0.0;
                    final rangeLabel = _selectedTimeRange == 'hour'
                        ? 'Hourly'
                        : _selectedTimeRange == 'week'
                            ? 'Weekly'
                            : 'Daily';

                    return Card(
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
                                Icon(
                                  Icons.info_outline,
                                  color: isDark ? AppColors.secondary : AppColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '$rangeLabel Summary',
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
                              label: 'Presence Events',
                              value: '${stats['presence_events'] as int? ?? 0}',
                            ),
                            const Divider(),
                            _SummaryRow(
                              label: 'Avg Brightness',
                              value:
                                  '${(stats['avg_brightness'] as num?)?.toStringAsFixed(1) ?? '0.0'}%',
                            ),
                            const Divider(),
                            _SummaryRow(
                              label: 'Active Time',
                              value: _formatDuration(activeTime.toInt()),
                            ),
                            const Divider(),
                            _SummaryRow(
                              label: 'Energy Saving Time',
                              value: _formatDuration(energySavingTime.toInt()),
                            ),
                            const Divider(),
                            _SummaryRow(
                              label: 'Energy Saved',
                              value: '${energySavedWh.toStringAsFixed(1)} Wh',
                            ),
                            const Divider(),
                            _SummaryRow(
                              label: 'Efficiency Score',
                              value: '${efficiency.toStringAsFixed(1)}%',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
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

  /// Chart helper: build brightness spots from feeds
  List<FlSpot> _buildBrightnessSpots(List feeds) {
    if (feeds.isEmpty) return [];
    final List<FlSpot> spots = [];
    for (final feed in feeds) {
      final t = feed.createdAt.millisecondsSinceEpoch.toDouble();
      final b = feed.getFieldAsDouble('brightness').clamp(0.0, 100.0);
      spots.add(FlSpot(t, b));
    }
    return spots;
  }

  /// Chart helper: build ambient light spots from feeds
  List<FlSpot> _buildAmbientLightSpots(List feeds) {
    if (feeds.isEmpty) return [];
    final List<FlSpot> spots = [];
    for (final feed in feeds) {
      final t = feed.createdAt.millisecondsSinceEpoch.toDouble();
      final lux = feed.getFieldAsDouble('ambient_light');
      if (lux > 0 || spots.isNotEmpty) {
        spots.add(FlSpot(t, lux));
      }
    }
    return spots;
  }

  /// X axis label formatter — uses actual DateTime for readability
  String _formatXLabel(double x, double maxX, String range) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(x.toInt());
    if (range == 'week') {
      // Show abbreviated day name (Sun, Mon, …, Sat)
      return DateFormat('E').format(dateTime);
    }
    // hour & day: show HH:mm
    return DateFormat('HH:mm').format(dateTime);
  }

  /// X axis interval in milliseconds by range
  double _xInterval(String range) {
    if (range == 'hour') return 10 * 60 * 1000.0;       // every 10 min
    if (range == 'week') return 24 * 60 * 60 * 1000.0;  // every day
    return 4 * 60 * 60 * 1000.0;                         // every 4 h (day)
  }

  /// Dynamic chart title
  String _brightnessTrendTitle(String range) {
    if (range == 'hour') return 'Brightness – Last Hour';
    if (range == 'week') return 'Brightness – Last 7 Days';
    return 'Brightness – Last 24 Hours';
  }

  String _brightnessTrendSubtitle(String range) {
    if (range == 'week') return 'X axis: day of week (Sun – Sat)';
    return 'X axis: actual time';
  }

  String _xAxisLabel(String range) {
    if (range == 'week') return 'Day';
    return 'Time';
  }


}

/// Presence Activity Timeline Widget
///
/// Shows a compact horizontal timeline strip where filled segments
/// indicate presence-detected intervals. This gives a lay user an
/// intuitive at-a-glance view of when the room was occupied.
class _PresenceTimeline extends StatelessWidget {
  final List feeds;
  final bool isDark;

  const _PresenceTimeline({required this.feeds, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (feeds.isEmpty) return const SizedBox.shrink();

    final firstTs = feeds.first.createdAt.millisecondsSinceEpoch;
    final lastTs = feeds.last.createdAt.millisecondsSinceEpoch;
    final span = (lastTs - firstTs).toDouble();
    if (span <= 0) return const SizedBox.shrink();

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
            Text(
              'Presence Activity',
              style: AppTextStyles.headline3.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            Text(
              'Green = someone present, grey = empty room',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              child: SizedBox(
                height: 28,
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final totalWidth = constraints.maxWidth;
                    return Stack(
                      children: [
                        // Background
                        Container(
                          width: totalWidth,
                          height: 28,
                          color: isDark
                              ? AppColors.darkCardBackground
                              : AppColors.cardBackground,
                        ),
                        // Presence segments
                        for (int i = 0; i < feeds.length - 1; i++)
                          if (feeds[i].getFieldAsBool('presence'))
                            Positioned(
                              left: ((feeds[i].createdAt.millisecondsSinceEpoch - firstTs) / span) * totalWidth,
                              width: ((feeds[i + 1].createdAt.millisecondsSinceEpoch - feeds[i].createdAt.millisecondsSinceEpoch) / span) * totalWidth + 1,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                color: AppColors.success.withValues(alpha: 0.75),
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Time labels: start and end
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('HH:mm').format(feeds.first.createdAt),
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 9,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(feeds.last.createdAt),
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 9,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

    // In light mode use accent so the small badge is clearly legible
    final badgeColor = !isDark && color == AppColors.accent
        ? AppColors.secondary
        : color;

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
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.sm,
                      ),
                    ),
                    child: Text(
                      '${(progressValue * 100).toInt()}%',
                      style: AppTextStyles.caption.copyWith(
                        color: badgeColor,
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
              ? (isDark ? AppColors.secondary : AppColors.primary)
              : (isDark
                  ? AppColors.primary
                  : AppColors.cardBackground),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? AppColors.primaryLight : AppColors.textSecondary.withValues(alpha: 0.3)),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected
                ? (isDark ? AppColors.primaryDark : Colors.white)
                : (isDark ? Colors.white : AppColors.textSecondary),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
