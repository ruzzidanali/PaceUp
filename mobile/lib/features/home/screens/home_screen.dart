import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/services/auth_state.dart';
import '../../dashboard/models/dashboard_models.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../streaks/models/streak_models.dart';
import '../../streaks/services/streak_service.dart';

class HomeScreen extends StatefulWidget {
  final AuthController authController;

  const HomeScreen({
    super.key,
    required this.authController,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DashboardService _dashboardService;
  late final StreakService _streakService;

  DashboardResponse? _dashboard;
  StreakResponse? _streak;

  bool _isLoading = true;
  bool _isStreakLoading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _dashboardService = DashboardService();
    _streakService = StreakService();

    _loadDashboard();
    _loadStreak();
  }

  @override
  void dispose() {
    _dashboardService.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashboard = await _dashboardService.getDashboard();

      if (!mounted) {
        return;
      }

      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadStreak() async {
    setState(() {
      _isStreakLoading = true;
    });

    try {
      final streak = await _streakService.getStreak();

      if (!mounted) {
        return;
      }

      setState(() {
        _streak = streak;
        _isStreakLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isStreakLoading = false;
        _streak = null;
      });
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m';
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  String _formatActivityType(String type) {
    if (type.isEmpty) {
      return 'Activity';
    }

    return type[0].toUpperCase() + type.substring(1).toLowerCase();
  }

  String _formatGoalValue(String type, double value) {
    switch (type.toLowerCase()) {
      case 'distance':
        return '${value.toStringAsFixed(1)} km';

      case 'duration':
        return _formatDuration(value.round());

      case 'calories':
        return '${value.round()} kcal';

      case 'activities':
        return '${value.round()} activities';

      default:
        return value.toStringAsFixed(1);
    }
  }

  IconData _activityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'run':
      case 'running':
        return Icons.directions_run_rounded;

      case 'walk':
      case 'walking':
        return Icons.directions_walk_rounded;

      case 'cycle':
      case 'cycling':
      case 'bike':
        return Icons.directions_bike_rounded;

      default:
        return Icons.fitness_center_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _dashboard == null) {
      return const _LoadingState();
    }

    if (_errorMessage != null && _dashboard == null) {
      return _ErrorState(
        message: _errorMessage!,
        onRetry: _loadDashboard,
      );
    }

    final dashboard = _dashboard!;

    return RefreshIndicator(
      color: PaceUpColors.electricGreen,
      backgroundColor: PaceUpColors.darkPanel,
      onRefresh: () async {
        await Future.wait([
          _loadDashboard(),
          _loadStreak(),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _GreetingSection(
            displayName:
                widget.authController.state.user?.displayName ?? 'Runner',
          ),
          const SizedBox(height: 24),
          _StreakHero(
            streak: _streak,
            isLoading: _isStreakLoading,
          ),
          const SizedBox(height: 28),
          const _SectionHeader(
            eyebrow: 'ACTIVITY',
            title: 'Your numbers',
          ),
          const SizedBox(height: 12),
          _SummaryGrid(
            summary: dashboard.activitySummary,
            formatDuration: _formatDuration,
          ),
          const SizedBox(height: 28),
          const _SectionHeader(
            eyebrow: 'TARGETS',
            title: 'Active goals',
          ),
          const SizedBox(height: 12),
          if (dashboard.activeGoals.isEmpty)
            const _EmptyCard(
              icon: Icons.flag_outlined,
              message: 'No active goals yet.',
            )
          else
            ...dashboard.activeGoals.map(
              (goal) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _GoalCard(
                  goal: goal,
                  formatGoalValue: _formatGoalValue,
                ),
              ),
            ),
          const SizedBox(height: 18),
          const _SectionHeader(
            eyebrow: 'HISTORY',
            title: 'Recent activities',
          ),
          const SizedBox(height: 12),
          if (dashboard.recentActivities.isEmpty)
            const _EmptyCard(
              icon: Icons.directions_run_outlined,
              message: 'No activities recorded yet.',
            )
          else
            ...dashboard.recentActivities.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActivityCard(
                  activity: activity,
                  icon: _activityIcon(activity.type),
                  formatDuration: _formatDuration,
                  formatDate: _formatDate,
                  formatActivityType: _formatActivityType,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  final String displayName;

  const _GreetingSection({
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Welcome back,',
                style: PaceUpTypography.body(
                  PaceUpColors.darkMuted,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PaceUpTypography.display(
                  PaceUpColors.darkText,
                ).copyWith(
                  fontSize: 42,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Keep moving. Keep building.',
                style: PaceUpTypography.body(
                  PaceUpColors.darkMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: PaceUpColors.darkPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: PaceUpColors.darkBorder,
            ),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: PaceUpColors.electricGreen,
          ),
        ),
      ],
    );
  }
}

class _StreakHero extends StatelessWidget {
  final StreakResponse? streak;
  final bool isLoading;

  const _StreakHero({
    required this.streak,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: PaceUpColors.darkPanel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: PaceUpColors.darkBorder,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: PaceUpColors.electricGreen,
          ),
        ),
      );
    }

    final currentStreak = streak?.currentStreak ?? 0;
    final longestStreak = streak?.longestStreak ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -38,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: PaceUpColors.electricGreen.withValues(
                    alpha: 0.12,
                  ),
                  width: 22,
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: PaceUpColors.electricGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: PaceUpColors.greenInk,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT STREAK',
                      style: PaceUpTypography.label(
                        PaceUpColors.darkMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$currentStreak',
                          style: PaceUpTypography.largeMetric(
                            PaceUpColors.darkText,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Text(
                            currentStreak == 1 ? 'DAY' : 'DAYS',
                            style: PaceUpTypography.label(
                              PaceUpColors.electricGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Best: $longestStreak days',
                      style: PaceUpTypography.body(
                        PaceUpColors.darkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: PaceUpTypography.sectionTitle(
            PaceUpColors.electricGreen,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: PaceUpTypography.heading(
            PaceUpColors.darkText,
          ),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final DashboardActivitySummary summary;
  final String Function(int) formatDuration;

  const _SummaryGrid({
    required this.summary,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      mainAxisExtent: 108,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          icon: Icons.directions_run_rounded,
          label: 'ACTIVITIES',
          value: summary.totalActivities.toString(),
        ),
        _SummaryCard(
          icon: Icons.straighten_rounded,
          label: 'DISTANCE',
          value: '${summary.totalDistance.toStringAsFixed(1)} km',
        ),
        _SummaryCard(
          icon: Icons.timer_outlined,
          label: 'DURATION',
          value: formatDuration(summary.totalDurationSeconds),
        ),
        _SummaryCard(
          icon: Icons.local_fire_department_outlined,
          label: 'CALORIES',
          value: '${summary.totalCalories} kcal',
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            size: 20,
            color: PaceUpColors.electricCyan,
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PaceUpTypography.largeMetric(
              PaceUpColors.darkText,
            ).copyWith(
              fontSize: 32,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PaceUpTypography.label(
              PaceUpColors.darkMuted,
            ).copyWith(
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final DashboardGoal goal;
  final String Function(String, double) formatGoalValue;

  const _GoalCard({
    required this.goal,
    required this.formatGoalValue,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (goal.progressPercentage / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${goal.type[0].toUpperCase()}'
                  '${goal.type.substring(1)} Goal',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PaceUpTypography.bodyMedium(
                    PaceUpColors.darkText,
                  ),
                ),
              ),
              Text(
                '${goal.progressPercentage.toStringAsFixed(0)}%',
                style: PaceUpTypography.bodyMedium(
                  PaceUpColors.electricGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: PaceUpColors.darkPanelSecondary,
              valueColor: const AlwaysStoppedAnimation(
                PaceUpColors.electricGreen,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatGoalValue(goal.type, goal.current)} / '
                  '${formatGoalValue(goal.type, goal.target)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PaceUpTypography.body(
                    PaceUpColors.darkMuted,
                  ),
                ),
              ),
              if (goal.isCompleted)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: PaceUpColors.electricGreen,
                )
              else
                Text(
                  '${formatGoalValue(goal.type, goal.remaining)} left',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PaceUpTypography.body(
                    PaceUpColors.darkMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final DashboardActivity activity;
  final IconData icon;
  final String Function(int) formatDuration;
  final String Function(DateTime) formatDate;
  final String Function(String) formatActivityType;

  const _ActivityCard({
    required this.activity,
    required this.icon,
    required this.formatDuration,
    required this.formatDate,
    required this.formatActivityType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanelSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: PaceUpColors.electricGreen,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatActivityType(activity.type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PaceUpTypography.bodyMedium(
                    PaceUpColors.darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatDate(activity.startedAt)} • '
                  '${formatDuration(activity.durationSeconds)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PaceUpTypography.body(
                    PaceUpColors.darkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${activity.distance.toStringAsFixed(1)} km',
                style: PaceUpTypography.bodyMedium(
                  PaceUpColors.darkText,
                ),
              ),
              if (activity.calories != null)
                Text(
                  '${activity.calories} kcal',
                  style: PaceUpTypography.body(
                    PaceUpColors.darkMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: PaceUpColors.darkMuted,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: PaceUpTypography.body(
              PaceUpColors.darkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: PaceUpColors.electricGreen,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: PaceUpColors.darkMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load dashboard',
              style: PaceUpTypography.heading(
                PaceUpColors.darkText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: PaceUpTypography.body(
                PaceUpColors.darkMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}