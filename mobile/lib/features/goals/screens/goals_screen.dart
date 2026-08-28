import 'package:flutter/material.dart';

import '../models/goal_models.dart';
import '../services/goal_service.dart';
import 'add_goal_screen.dart';
import 'goal_details_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late final GoalService _goalService;

  List<GoalResponse> _goals = [];
  final Map<String, GoalProgressResponse> _progress = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _goalService = GoalService();
    _loadGoals();
  }

  @override
  void dispose() {
    _goalService.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final goals = await _goalService.getGoals();

      final progressEntries = await Future.wait(
        goals.map((goal) async {
          try {
            final progress = await _goalService.getProgress(goal.id);

            return MapEntry(goal.id, progress);
          } catch (_) {
            return null;
          }
        }),
      );

      if (!mounted) {
        return;
      }

      final progress = <String, GoalProgressResponse>{};

      for (final entry in progressEntries) {
        if (entry != null) {
          progress[entry.key] = entry.value;
        }
      }

      setState(() {
        _goals = goals;
        _progress
          ..clear()
          ..addAll(progress);
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

  Future<void> _addGoal() async {
    final created = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const AddGoalScreen()));

    if (created == true && mounted) {
      await _loadGoals();
    }
  }

  Future<void> _openGoal(GoalResponse goal) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => GoalDetailsScreen(goal: goal)),
    );

    if (changed == true && mounted) {
      await _loadGoals();
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _formatTarget(GoalResponse goal) {
    switch (goal.type) {
      case 'Distance':
        return '${goal.target.toStringAsFixed(1)} km';

      case 'Duration':
        return _formatDuration(goal.target.round());

      case 'Calories':
        return '${goal.target.round()} kcal';

      case 'Activities':
        return '${goal.target.round()} activities';

      default:
        return goal.target.toString();
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m';
  }

  IconData _goalIcon(String type) {
    switch (type) {
      case 'Distance':
        return Icons.straighten_rounded;

      case 'Duration':
        return Icons.timer_outlined;

      case 'Calories':
        return Icons.local_fire_department_outlined;

      case 'Activities':
        return Icons.directions_run_rounded;

      default:
        return Icons.flag_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _addGoal,
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
      ),
      body: RefreshIndicator(onRefresh: _loadGoals, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.error_outline, size: 56),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadGoals,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      );
    }

    if (_goals.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.flag_outlined, size: 64),
          const SizedBox(height: 20),
          Text(
            'No goals yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first running goal and start tracking your progress.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _addGoal,
            icon: const Icon(Icons.add),
            label: const Text('Create Goal'),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];

        return _GoalCard(
          goal: goal,
          progress: _progress[goal.id],
          icon: _goalIcon(goal.type),
          targetLabel: _formatTarget(goal),
          startDate: _formatDate(goal.startDate),
          endDate: _formatDate(goal.endDate),
          onTap: () => _openGoal(goal),
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalResponse goal;
  final GoalProgressResponse? progress;
  final IconData icon;
  final String targetLabel;
  final String startDate;
  final String endDate;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.progress,
    required this.icon,
    required this.targetLabel,
    required this.startDate,
    required this.endDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressValue = progress == null
        ? 0.0
        : (progress!.progressPercentage / 100).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(child: Icon(icon)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.type,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    targetLabel,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '$startDate – $endDate',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progressValue),
              const SizedBox(height: 8),
              if (progress != null)
                Row(
                  children: [
                    Text(
                      '${progress!.progressPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      progress!.isCompleted
                          ? 'Completed'
                          : '${progress!.remaining.toStringAsFixed(1)} remaining',
                    ),
                  ],
                )
              else
                const Text('Progress unavailable'),
            ],
          ),
        ),
      ),
    );
  }
}
