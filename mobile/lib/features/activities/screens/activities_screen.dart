import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/activity_models.dart';
import '../services/activity_service.dart';
import 'activity_details_screen.dart';
import 'add_activity_screen.dart';
import 'fitness_statistics_screen.dart';
import '../../tracking/screens/tracking_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  late final ActivityService _activityService;

  PagedActivityResponse? _activities;
  ActivityStatsResponse? _stats;

  String? _selectedType;

  bool _isLoading = true;
  bool _isFiltering = false;

  String? _errorMessage;

  static const _activityTypes = [
    'Run',
    'Ride',
    'Walk',
    'Hike',
    'Swim',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _activityService = ActivityService();

    _loadActivities();
  }

  @override
  void dispose() {
    _activityService.dispose();
    super.dispose();
  }

  Future<void> _openAddActivity() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddActivityScreen()));

    if (created == true && mounted) {
      await _loadActivities();
    }
  }

  Future<void> _openTracking() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const TrackingScreen()));
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _activityService.getActivities(
          page: 1,
          pageSize: 20,
          type: _selectedType,
        ),
        _activityService.getStats(type: _selectedType),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _activities = results[0] as PagedActivityResponse;
        _stats = results[1] as ActivityStatsResponse;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadActivities();
  }

  Future<void> _onFilterChanged(String? type) async {
    if (_selectedType == type || _isFiltering) {
      return;
    }

    final previousType = _selectedType;

    setState(() {
      _selectedType = type;
      _isFiltering = true;
    });

    try {
      final results = await Future.wait([
        _activityService.getActivities(page: 1, pageSize: 20, type: type),
        _activityService.getStats(type: type),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _activities = results[0] as PagedActivityResponse;
        _stats = results[1] as ActivityStatsResponse;
        _errorMessage = null;
        _isFiltering = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedType = previousType;
        _isFiltering = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? PaceUpColors.darkBackground
        : PaceUpColors.lightBackground;

    if (_isLoading) {
      return Container(
        color: backgroundColor,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: PaceUpColors.electricGreen,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(
                    color: PaceUpColors.electricGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(backgroundColor);
    }

    return Container(
      color: backgroundColor,
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: PaceUpColors.electricGreen,
        backgroundColor: isDark
            ? PaceUpColors.darkPanel
            : PaceUpColors.lightPanel,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final activities = _activities?.items ?? [];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? PaceUpColors.darkText : PaceUpColors.lightText;

    final mutedColor = isDark
        ? PaceUpColors.darkMuted
        : PaceUpColors.lightMuted;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 110),
      children: [
        _buildHeader(textColor: textColor, mutedColor: mutedColor),
        const SizedBox(height: 22),
        _buildActionPanel(textColor: textColor, mutedColor: mutedColor),
        const SizedBox(height: 22),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.025),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey('stats-${_selectedType ?? 'all'}'),
            child: _buildStatsCard(
              textColor: textColor,
              mutedColor: mutedColor,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildFilterSection(textColor: textColor, mutedColor: mutedColor),
        const SizedBox(height: 22),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.025),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey('activities-${_selectedType ?? 'all'}'),
            child: _buildActivitySection(
              activities: activities,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({required Color textColor, required Color mutedColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Text(
          'Your activities.',
          style: PaceUpTypography.heading(textColor).copyWith(fontSize: 30),
        ),
        const SizedBox(height: 5),
        Text(
          'Track your movement and keep building.',
          style: PaceUpTypography.body(mutedColor),
        ),
      ],
    );
  }

  Widget _buildActionPanel({
    required Color textColor,
    required Color mutedColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final panelColor = isDark
        ? PaceUpColors.darkPanel
        : PaceUpColors.lightPanel;

    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _openTracking,
                style: FilledButton.styleFrom(
                  backgroundColor: PaceUpColors.electricGreen,
                  foregroundColor: PaceUpColors.greenInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  'TRACK',
                  style: PaceUpTypography.label(PaceUpColors.greenInk),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 52,
            width: 52,
            child: OutlinedButton(
              onPressed: _openAddActivity,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: textColor,
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required Color textColor,
    required Color mutedColor,
  }) {
    final stats = _stats;

    if (stats == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final panelColor = isDark
        ? PaceUpColors.darkPanel
        : PaceUpColors.lightPanel;

    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    final title = _selectedType == null
        ? 'ALL ACTIVITIES'
        : _selectedType!.toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: PaceUpTypography.sectionTitle(
                    PaceUpColors.electricGreen,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FitnessStatisticsScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(9),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: PaceUpColors.electricCyan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: PaceUpColors.electricCyan.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.analytics_outlined,
                          color: PaceUpColors.electricCyan,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'STATS',
                          style: PaceUpTypography.label(
                            PaceUpColors.electricCyan,
                          ).copyWith(fontSize: 9, letterSpacing: 1.1),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: PaceUpColors.electricCyan,
                          size: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  value: stats.totalActivities.toString(),
                  label: 'ACTIVITIES',
                  accent: PaceUpColors.electricGreen,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
              _StatDivider(color: borderColor),
              Expanded(
                child: _StatBlock(
                  value: '${stats.totalDistance.toStringAsFixed(1)} km',
                  label: 'DISTANCE',
                  accent: PaceUpColors.electricCyan,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: borderColor),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  value: _formatDuration(stats.totalDurationSeconds),
                  label: 'DURATION',
                  accent: PaceUpColors.electricCyan,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
              _StatDivider(color: borderColor),
              Expanded(
                child: _StatBlock(
                  value: '${stats.totalCalories} kcal',
                  label: 'CALORIES',
                  accent: PaceUpColors.electricGreen,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required Color textColor,
    required Color mutedColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVITY TYPE',
          style: PaceUpTypography.sectionTitle(PaceUpColors.electricGreen),
        ),
        const SizedBox(height: 11),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: _selectedType == null,
                onSelected: () => _onFilterChanged(null),
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              ..._activityTypes.map(
                (type) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _FilterChip(
                    label: type,
                    selected: _selectedType == type,
                    onSelected: () => _onFilterChanged(type),
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isFiltering) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: PaceUpColors.electricGreen,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Updating activities...',
                style: PaceUpTypography.body(mutedColor).copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActivitySection({
    required List<ActivityResponse> activities,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'RECENT ACTIVITIES',
                style: PaceUpTypography.sectionTitle(
                  PaceUpColors.electricGreen,
                ),
              ),
            ),
            Text(
              '${activities.length}',
              style: PaceUpTypography.label(mutedColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          _buildEmptyState(textColor: textColor, mutedColor: mutedColor)
        else
          ...activities.map(
            (activity) => _buildActivityCard(
              activity,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
          ),
      ],
    );
  }

  Widget _buildActivityCard(
    ActivityResponse activity, {
    required Color textColor,
    required Color mutedColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final panelColor = isDark
        ? PaceUpColors.darkPanel
        : PaceUpColors.lightPanel;

    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    final accent = _activityAccent(activity.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final deleted = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ActivityDetailsScreen(activity: activity),
              ),
            );

            if (deleted == true && mounted) {
              await _loadActivities();
            }
          },
          child: Ink(
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Icon(
                          _activityIcon(activity.type),
                          color: accent,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.type.toUpperCase(),
                              style: PaceUpTypography.sectionTitle(accent),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatDate(activity.startedAt),
                              style: PaceUpTypography.body(mutedColor)
                                  .copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: mutedColor),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Expanded(
                        child: _ActivityMetric(
                          value: '${activity.distance.toStringAsFixed(2)} km',
                          label: 'DISTANCE',
                          accent: accent,
                          textColor: textColor,
                          mutedColor: mutedColor,
                        ),
                      ),
                      _StatDivider(color: borderColor),
                      Expanded(
                        child: _ActivityMetric(
                          value: _formatDuration(activity.durationSeconds),
                          label: 'DURATION',
                          accent: PaceUpColors.electricCyan,
                          textColor: textColor,
                          mutedColor: mutedColor,
                        ),
                      ),
                      _StatDivider(color: borderColor),
                      Expanded(
                        child: _ActivityMetric(
                          value: _formatPace(activity),
                          label: 'PACE',
                          accent: textColor,
                          textColor: textColor,
                          mutedColor: mutedColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatSpeed(activity),
                          style: PaceUpTypography.body(mutedColor)
                              .copyWith(fontSize: 11),
                        ),
                      ),
                      if (activity.calories != null)
                        Text(
                          '${activity.calories} kcal',
                          style: PaceUpTypography.body(mutedColor)
                              .copyWith(fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required Color textColor,
    required Color mutedColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final panelColor = isDark
        ? PaceUpColors.darkPanel
        : PaceUpColors.lightPanel;

    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.directions_run_rounded,
            size: 46,
            color: PaceUpColors.electricGreen,
          ),
          const SizedBox(height: 15),
          Text(
            _selectedType == null
                ? 'NO ACTIVITIES YET'
                : 'NO ${_selectedType!.toUpperCase()} ACTIVITIES',
            style: PaceUpTypography.sectionTitle(PaceUpColors.electricGreen),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 9),
          Text(
            'Your activities will appear here once you start recording them.',
            textAlign: TextAlign.center,
            style: PaceUpTypography.body(mutedColor),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: _openTracking,
              style: FilledButton.styleFrom(
                backgroundColor: PaceUpColors.electricGreen,
                foregroundColor: PaceUpColors.greenInk,
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                'START TRACKING',
                style: PaceUpTypography.label(PaceUpColors.greenInk),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color backgroundColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mutedColor = isDark
        ? PaceUpColors.darkMuted
        : PaceUpColors.lightMuted;

    return Container(
      color: backgroundColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.32,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 48, color: mutedColor),
                    const SizedBox(height: 17),
                    Text(
                      'ACTIVITIES UNAVAILABLE',
                      style: PaceUpTypography.sectionTitle(
                        PaceUpColors.electricGreen,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      _errorMessage ?? 'Unable to load activities.',
                      textAlign: TextAlign.center,
                      style: PaceUpTypography.body(mutedColor),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 46,
                      child: FilledButton.icon(
                        onPressed: _loadActivities,
                        style: FilledButton.styleFrom(
                          backgroundColor: PaceUpColors.electricGreen,
                          foregroundColor: PaceUpColors.greenInk,
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(
                          'TRY AGAIN',
                          style: PaceUpTypography.label(PaceUpColors.greenInk),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'Run':
        return Icons.directions_run_rounded;

      case 'Ride':
        return Icons.directions_bike_rounded;

      case 'Walk':
        return Icons.directions_walk_rounded;

      case 'Hike':
        return Icons.hiking_rounded;

      case 'Swim':
        return Icons.pool_rounded;

      default:
        return Icons.fitness_center_rounded;
    }
  }

  Color _activityAccent(String type) {
    switch (type) {
      case 'Run':
        return PaceUpColors.electricGreen;

      case 'Ride':
        return PaceUpColors.electricCyan;

      case 'Walk':
        return PaceUpColors.electricGreen;

      case 'Hike':
        return PaceUpColors.electricCyan;

      case 'Swim':
        return PaceUpColors.electricCyan;

      default:
        return PaceUpColors.electricGreen;
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }

    return '${seconds}s';
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }
}

String _formatPace(ActivityResponse activity) {
  if (activity.distance <= 0 || activity.durationSeconds <= 0) {
    return '--';
  }

  final secondsPerKm = activity.durationSeconds / activity.distance;

  final totalSeconds = secondsPerKm.round();

  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;

  return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
}

String _formatSpeed(ActivityResponse activity) {
  if (activity.distance <= 0 || activity.durationSeconds <= 0) {
    return '--';
  }

  final speedKmh = activity.distance * 3600 / activity.durationSeconds;

  return '${speedKmh.toStringAsFixed(1)} km/h';
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;
  final Color textColor;
  final Color mutedColor;

  const _StatBlock({
    required this.value,
    required this.label,
    required this.accent,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PaceUpTypography.largeMetric(accent).copyWith(fontSize: 28),
        ),
        const SizedBox(height: 4),
        Text(label, style: PaceUpTypography.label(mutedColor)),
      ],
    );
  }
}

class _ActivityMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;
  final Color textColor;
  final Color mutedColor;

  const _ActivityMetric({
    required this.value,
    required this.label,
    required this.accent,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PaceUpTypography.bodyMedium(textColor)
              .copyWith(color: accent, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(label, style: PaceUpTypography.label(mutedColor)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  final Color color;

  const _StatDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: color,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color textColor;
  final Color mutedColor;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? PaceUpColors.electricGreen
        : (Theme.of(context).brightness == Brightness.dark
              ? PaceUpColors.darkBorder
              : PaceUpColors.lightBorder);

    final backgroundColor = selected
        ? PaceUpColors.electricGreen.withValues(alpha: 0.10)
        : (Theme.of(context).brightness == Brightness.dark
              ? PaceUpColors.darkPanel
              : PaceUpColors.lightPanel);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(9),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            label.toUpperCase(),
            style: PaceUpTypography.label(
              selected ? PaceUpColors.electricGreen : mutedColor,
            ),
          ),
        ),
      ),
    );
  }
}
