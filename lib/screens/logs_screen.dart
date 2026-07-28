/// Logs Screen
/// 
/// A screen for displaying chronological event history with
/// pull-to-refresh functionality and event type filtering.
/// 
/// Purpose: Provide users with a detailed view of system events
/// including presence detection, brightness changes, state transitions,
/// and mode changes.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_light/providers/system_provider.dart';
import 'package:smart_light/utils/constants.dart';
import 'package:smart_light/models/event_log.dart';

/// Logs Screen
/// 
/// Displays event log history with filtering and refresh capabilities.
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshLogs();
    });
  }

  Future<void> _refreshLogs() async {
    final provider = Provider.of<SystemProvider>(context, listen: false);
    await provider.refreshLogs();
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
              title: const Text('Event Logs'),
              elevation: 0,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (filter) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'All',
                      child: Text('All Events'),
                    ),
                    const PopupMenuItem(
                      value: 'presence',
                      child: Text('Presence Events'),
                    ),
                    const PopupMenuItem(
                      value: 'brightness',
                      child: Text('Brightness Events'),
                    ),
                    const PopupMenuItem(
                      value: 'state',
                      child: Text('State Changes'),
                    ),
                    const PopupMenuItem(
                      value: 'mode',
                      child: Text('Mode Changes'),
                    ),
                    const PopupMenuItem(
                      value: 'system',
                      child: Text('System Events'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<SystemProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingLogs) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final logs = provider.eventLogs;
          final filteredLogs = _selectedFilter == 'All'
              ? logs.logs
              : logs.filterByType(_selectedFilter).logs;

          if (filteredLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No events logged',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshLogs,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: filteredLogs.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final log = filteredLogs[index];
                return _LogTile(log: log);
              },
            ),
          );
        },
      ),
    );
  }
}

/// Log Tile
/// 
/// Internal widget for displaying a single log entry.
class _LogTile extends StatelessWidget {
  final EventLog log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Event Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getEventTypeColor(log.eventType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Center(
                child: Icon(
                  _getEventIcon(log.eventType),
                  color: _getEventTypeColor(log.eventType),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Event Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (log.details != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      log.details!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        log.formattedTime,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        log.formattedDate,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _formatEventType(log.eventType),
                        style: AppTextStyles.caption.copyWith(
                          color: _getEventTypeColor(log.eventType),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get event type color
  Color _getEventType(String type) {
    switch (type.toLowerCase()) {
      case 'presence':
        return AppColors.success;
      case 'brightness':
        return AppColors.accent;
      case 'state':
        return AppColors.warning;
      case 'mode':
        return AppColors.primary;
      case 'system':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Get event type color for UI
  Color _getEventTypeColor(String type) {
    return _getEventType(type);
  }

  /// Format event type for display
  String _formatEventType(String type) {
    switch (type.toLowerCase()) {
      case 'presence':
        return 'Presence';
      case 'brightness':
        return 'Brightness';
      case 'state':
        return 'State';
      case 'mode':
        return 'Mode';
      case 'system':
        return 'System';
      default:
        return type;
    }
  }

  /// Get event type icon
  IconData _getEventIcon(String type) {
    switch (type.toLowerCase()) {
      case 'presence':
        return Icons.person;
      case 'brightness':
        return Icons.lightbulb;
      case 'state':
        return Icons.swap_horiz_rounded;
      case 'mode':
        return Icons.settings;
      case 'system':
        return Icons.build;
      default:
        return Icons.info;
    }
  }
}
