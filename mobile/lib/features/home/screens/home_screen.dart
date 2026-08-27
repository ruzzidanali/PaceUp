import 'package:flutter/material.dart';

import '../../auth/services/auth_state.dart';
import '../../dashboard/models/dashboard_models.dart';
import '../../dashboard/services/dashboard_service.dart';

class HomeScreen extends StatefulWidget {
  final AuthController authController;

  const HomeScreen({super.key, required this.authController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DashboardService _dashboardService;

  DashboardResponse? _dashboard;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dashboardService = DashboardService();
    _loadDashboard();
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _dashboard == null) {
      return _ErrorState(message: _errorMessage!, onRetry: _loadDashboard);
    }

    final dashboard = _dashboard!;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _GreetingSection(
            displayName:
                widget.authController.state.user?.displayName ?? 'runner',
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Your Progress'),
          const SizedBox(height: 12),
          _SummaryGrid(
            summary: dashboard.activitySummary,
            formatDuration: _formatDuration,
          ),
          const SizedBox(height: 28),
          _SectionTitle(title: 'Active Goals'),
          const SizedBox(height: 12),
          if (dashboard.activeGoals.isEmpty)
            const _EmptyCard(
              icon: Icons.flag_outlined,
              message: 'No active goals yet.',
            )
          else
            ...dashboard.activeGoals.map(
              (goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GoalCard(goal: goal, formatGoalValue: _formatGoalValue),
              ),
            ),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Recent Activities'),
          const SizedBox(height: 12),
          if (dashboard.recentActivities.isEmpty)
            const _EmptyCard(
              icon: Icons.directions_run_outlined,
              message: 'No activities recorded yet.',
            )
          else
            ...dashboard.recentActivities.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
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

  const _GreetingSection({required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back,', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 4),
        Text(
          '$displayName!',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Keep moving and keep making progress.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final DashboardActivitySummary summary;
  final String Function(int) formatDuration;

  const _SummaryGrid({required this.summary, required this.formatDuration});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          icon: Icons.directions_run_rounded,
          label: 'Activities',
          value: summary.totalActivities.toString(),
        ),
        _SummaryCard(
          icon: Icons.straighten_rounded,
          label: 'Distance',
          value: '${summary.totalDistance.toStringAsFixed(1)} km',
        ),
        _SummaryCard(
          icon: Icons.timer_outlined,
          label: 'Duration',
          value: formatDuration(summary.totalDurationSeconds),
        ),
        _SummaryCard(
          icon: Icons.local_fire_department_outlined,
          label: 'Calories',
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final DashboardGoal goal;
  final String Function(String, double) formatGoalValue;

  const _GoalCard({required this.goal, required this.formatGoalValue});

  @override
  Widget build(BuildContext context) {
    final progress = (goal.progressPercentage / 100).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${goal.type[0].toUpperCase()}${goal.type.substring(1)} Goal',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${goal.progressPercentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatGoalValue(goal.type, goal.current)} / '
                    '${formatGoalValue(goal.type, goal.target)}',
                  ),
                ),
                !goal.isCompleted
                    ? Text(
                        '${formatGoalValue(goal.type, goal.remaining)} left',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : const Icon(Icons.check_circle_outline, size: 20),
              ],
            ),
          ],
        ),
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
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(
          formatActivityType(activity.type),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${formatDate(activity.startedAt)} • '
          '${formatDuration(activity.durationSeconds)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${activity.distance.toStringAsFixed(1)} km',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (activity.calories != null)
              Text(
                '${activity.calories} kcal',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48),
            const SizedBox(height: 16),
            Text(
              'Unable to load dashboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
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
