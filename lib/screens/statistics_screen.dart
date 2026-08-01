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
                              final spotData = _buildBrightnessSpots(feeds);
                              final spots = spotData.spots;
                              final timestamps = spotData.timestamps;
                              final maxX = (spots.length - 1).clamp(0.0, double.infinity).toDouble();
                              final minX = 0.0;
                              return LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    horizontalInterval: 20,
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
                                        reservedSize: 42,
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          if (idx < 0 || idx >= spots.length) {
                                            return const SizedBox.shrink();
                                          }
                                          // Show ~6 evenly spaced labels
                                          final step = (spots.length / 6).ceil().clamp(1, spots.length);
                                          if (idx % step != 0 && idx != spots.length - 1) {
                                            return const SizedBox.shrink();
                                          }
                                          final dt = timestamps[idx];
                                          final label = _selectedTimeRange == 'week'
                                              ? DateFormat('E').format(dt)
                                              : DateFormat('HH:mm').format(dt);
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
                                      isCurved: false,
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
                                          final idx = spot.x.toInt();
                                          if (idx < 0 || idx >= timestamps.length) return null;
                                          final dt = timestamps[idx];
                                          return LineTooltipItem(
                                            '${DateFormat('HH:mm').format(dt)}\n${spot.y.toStringAsFixed(0)}%',
                                            const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          );
                                        }).whereType<LineTooltipItem>().toList();
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

                   // Ambient Light Over Time — Bar Chart
                   if (feeds.isNotEmpty)
                     Builder(builder: (context) {
                       final ambSpotData = _buildAmbientLightSpots(feeds);
                       final ambSpots = ambSpotData.spots;
                       final ambTimestamps = ambSpotData.timestamps;
                       if (ambSpots.isEmpty) return const SizedBox.shrink();
                       final maxAmbY = ambSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
                       final yMax = maxAmbY < 10 ? 10.0 : (maxAmbY * 1.2);
                       final barWidth = ambSpots.length < 20 ? 14.0 : 6.0;
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
                                 'Average room brightness per time slot',
                                 style: AppTextStyles.bodySmall.copyWith(
                                   color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                 ),
                               ),
                               const SizedBox(height: AppSpacing.lg),
                               SizedBox(
                                 height: 210,
                                 child: BarChart(
                                   BarChartData(
                                     alignment: BarChartAlignment.spaceAround,
                                     maxY: yMax,
                                     minY: 0,
                                     barTouchData: BarTouchData(
                                       touchTooltipData: BarTouchTooltipData(
                                         getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                           if (groupIndex >= ambTimestamps.length) return null;
                                           final dt = ambTimestamps[groupIndex];
                                           final label = _selectedTimeRange == 'week'
                                               ? DateFormat('E').format(dt)
                                               : DateFormat('HH:mm').format(dt);
                                           return BarTooltipItem(
                                             '$label\n${rod.toY.toStringAsFixed(1)} lux',
                                             const TextStyle(
                                               color: Colors.white,
                                               fontSize: 11,
                                               fontWeight: FontWeight.w600,
                                             ),
                                           );
                                         },
                                       ),
                                     ),
                                     titlesData: FlTitlesData(
                                       rightTitles: const AxisTitles(
                                         sideTitles: SideTitles(showTitles: false),
                                       ),
                                       topTitles: const AxisTitles(
                                         sideTitles: SideTitles(showTitles: false),
                                       ),
                                       bottomTitles: AxisTitles(
                                         sideTitles: SideTitles(
                                           showTitles: true,
                                           reservedSize: 42,
                                           getTitlesWidget: (value, meta) {
                                             final idx = value.toInt();
                                             if (idx < 0 || idx >= ambSpots.length) {
                                               return const SizedBox.shrink();
                                             }
                                             // Show ~6 evenly spaced labels
                                             final step = (ambSpots.length / 6)
                                                 .ceil()
                                                 .clamp(1, ambSpots.length);
                                             if (idx % step != 0 &&
                                                 idx != ambSpots.length - 1) {
                                               return const SizedBox.shrink();
                                             }
                                             final dt = ambTimestamps[idx];
                                             final label = _selectedTimeRange == 'week'
                                                 ? DateFormat('E').format(dt)
                                                 : DateFormat('HH:mm').format(dt);
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
                                         sideTitles: SideTitles(
                                           showTitles: true,
                                           reservedSize: 44,
                                           getTitlesWidget: (value, meta) {
                                             if (value == meta.max) return const SizedBox.shrink();
                                             return Text(
                                               '${value.toInt()}lx',
                                               style: AppTextStyles.caption.copyWith(
                                                 fontSize: 9,
                                                 color: isDark
                                                     ? AppColors.darkTextSecondary
                                                     : AppColors.textSecondary,
                                               ),
                                             );
                                           },
                                         ),
                                       ),
                                     ),
                                     gridData: FlGridData(
                                       show: true,
                                       drawVerticalLine: false,
                                       getDrawingHorizontalLine: (_) => FlLine(
                                         color: isDark ? Colors.white10 : Colors.black12,
                                         strokeWidth: 1,
                                       ),
                                     ),
                                     borderData: FlBorderData(show: false),
                                     barGroups: ambSpots.asMap().entries.map((e) {
                                       return BarChartGroupData(
                                         x: e.key,
                                         barRods: [
                                           BarChartRodData(
                                             toY: e.value.y,
                                             color: AppColors.warning,
                                             width: barWidth,
                                             borderRadius: const BorderRadius.vertical(
                                               top: Radius.circular(4),
                                             ),
                                             backDrawRodData: BackgroundBarChartRodData(
                                               show: true,
                                               toY: yMax,
                                               color: isDark
                                                   ? Colors.white.withValues(alpha: 0.04)
                                                   : Colors.black.withValues(alpha: 0.03),
                                             ),
                                           ),
                                         ],
                                       );
                                     }).toList(),
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

  // ---------------------------------------------------------------------------
  // Data processing helpers
  // ---------------------------------------------------------------------------

  /// Bucket size in milliseconds for each time range.
  int _bucketMs(String range) {
    if (range == 'hour') return 5 * 60 * 1000;         // 5-min buckets
    if (range == 'week') return 3 * 60 * 60 * 1000;    // 3-hour buckets
    return 15 * 60 * 1000;                              // 15-min buckets (day)
  }

  /// Sorts [feeds] by timestamp, removes entries with duplicate timestamps,
  /// then averages [getValue] within fixed time buckets of [bucketMs].
  /// Returns a record with evenly sampled spots and parallel timestamps.
  ({List<FlSpot> spots, List<DateTime> timestamps}) _buildSpots(
    List feeds,
    double Function(dynamic feed) getValue, {
    required String range,
    double clampMin = 0.0,
    double clampMax = double.infinity,
  }) {
    if (feeds.isEmpty) return (spots: <FlSpot>[], timestamps: <DateTime>[]);

    // 1. Sort ascending by timestamp
    final sorted = [...feeds]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // 2. Remove duplicate timestamps (keep last seen)
    final Map<int, dynamic> deduped = {};
    for (final f in sorted) {
      deduped[f.createdAt.millisecondsSinceEpoch] = f;
    }
    final unique = deduped.values.toList();

    // 3. Bucket into fixed intervals and average
    final bms = _bucketMs(range);
    final Map<int, List<double>> buckets = {};
    for (final f in unique) {
      final ms = f.createdAt.millisecondsSinceEpoch;
      final bucket = (ms ~/ bms) * bms;
      final v = getValue(f);
      if (v.isNaN || v.isInfinite) continue;
      buckets.putIfAbsent(bucket, () => []).add(v.clamp(clampMin, clampMax));
    }

    if (buckets.isEmpty) return (spots: <FlSpot>[], timestamps: <DateTime>[]);

    // 4. Build sorted averaged spots
    final keys = buckets.keys.toList()..sort();
    final spots = <FlSpot>[];
    final timestamps = <DateTime>[];
    for (int i = 0; i < keys.length; i++) {
      final k = keys[i];
      final avg = buckets[k]!.reduce((a, b) => a + b) / buckets[k]!.length;
      spots.add(FlSpot(i.toDouble(), avg));
      timestamps.add(DateTime.fromMillisecondsSinceEpoch(k));
    }
    return (spots: spots, timestamps: timestamps);
  }

  /// Build brightness spots (0–100%).
  ({List<FlSpot> spots, List<DateTime> timestamps}) _buildBrightnessSpots(List feeds) => _buildSpots(
        feeds,
        (f) => f.getFieldAsDouble('brightness'),
        range: _selectedTimeRange,
        clampMin: 0.0,
        clampMax: 100.0,
      );

  /// Build ambient-light spots (lux, unbounded above).
  ({List<FlSpot> spots, List<DateTime> timestamps}) _buildAmbientLightSpots(List feeds) => _buildSpots(
        feeds,
        (f) => f.getFieldAsDouble('ambient_light'),
        range: _selectedTimeRange,
        clampMin: 0.0,
      );

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




}

/// Presence Activity Timeline Widget
///
/// Horizontal timeline strip: GREEN = presence detected, GREY = no presence.
/// Segments are proportional to how long each state lasted.
class _PresenceTimeline extends StatelessWidget {
  final List feeds;
  final bool isDark;

  const _PresenceTimeline({required this.feeds, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (feeds.isEmpty) return const SizedBox.shrink();

    // Sort chronologically and deduplicate
    final sorted = [...feeds]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final Map<int, dynamic> seen = {};
    for (final f in sorted) {
      seen[f.createdAt.millisecondsSinceEpoch] = f;
    }
    final unique = seen.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final firstTs = unique.first.createdAt.millisecondsSinceEpoch;
    final lastTs  = unique.last.createdAt.millisecondsSinceEpoch;
    final span    = (lastTs - firstTs).toDouble();
    if (span <= 0) return const SizedBox.shrink();

    // Explicit grey so it's visible on both light and dark themes
    final emptyColor  = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final presentColor = AppColors.success.withValues(alpha: 0.85);

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
                // Legend dots
                Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: presentColor, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('Present',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                const SizedBox(width: 12),
                Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: emptyColor, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('Empty',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                const Spacer(),
                Text('Presence Activity',
                  style: AppTextStyles.headline3.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  )),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // ── Timeline bar ──
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 32,
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final W = constraints.maxWidth;
                    return Row(
                      children: [
                        for (int i = 0; i < unique.length - 1; i++)
                          Builder(builder: (_) {
                            final tStart = unique[i].createdAt.millisecondsSinceEpoch;
                            final tEnd   = unique[i + 1].createdAt.millisecondsSinceEpoch;
                            final frac   = (tEnd - tStart) / span;
                            final w      = (frac * W).clamp(0.5, W);
                            final present = unique[i].getFieldAsBool('presence');
                            return Container(
                              width: w,
                              height: 32,
                              color: present ? presentColor : emptyColor,
                            );
                          }),
                        // Fill the last point's color to the end
                        Expanded(
                          child: Container(
                            height: 32,
                            color: unique.last.getFieldAsBool('presence')
                                ? presentColor
                                : emptyColor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Start / end time labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('HH:mm').format(unique.first.createdAt),
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 9,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(unique.last.createdAt),
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
