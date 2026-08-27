import 'package:flutter/material.dart';

import '../models/goal_models.dart';
import '../services/goal_service.dart';
import 'add_goal_screen.dart';

class GoalDetailsScreen extends StatefulWidget {
  final GoalResponse goal;

  const GoalDetailsScreen({super.key, required this.goal});

  @override
  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen> {
  late final GoalService _goalService;

  late GoalResponse _goal;
  GoalProgressResponse? _progress;

  bool _isLoading = true;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _goalService = GoalService();
    _goal = widget.goal;

    _loadProgress();
  }

  @override
  void dispose() {
    _goalService.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final progress = await _goalService.getProgress(_goal.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _progress = progress;
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

  Future<void> _edit() async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => AddGoalScreen(goal: _goal)));

    if (changed != true || !mounted) {
      return;
    }

    try {
      final updated = await _goalService.getGoal(_goal.id);

      setState(() {
        _goal = updated;
      });

      await _loadProgress();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Goal?'),
          content: const Text('This goal will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _goalService.deleteGoal(_goal.id);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });

      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _formatValue(double value, String type) {
    switch (type) {
      case 'Distance':
        return '${value.toStringAsFixed(1)} km';

      case 'Duration':
        final seconds = value.round();
        final hours = seconds ~/ 3600;
        final minutes = (seconds % 3600) ~/ 60;

        if (hours > 0) {
          return '${hours}h ${minutes}m';
        }

        return '${minutes}m';

      case 'Calories':
        return '${value.round()} kcal';

      case 'Activities':
        return '${value.round()} activities';

      default:
        return value.toString();
    }
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
    final progressValue = _progress == null
        ? 0.0
        : (_progress!.progressPercentage / 100).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(_goal.type),
        actions: [
          IconButton(
            onPressed: _isDeleting ? null : _edit,
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _isDeleting ? null : _delete,
            tooltip: 'Delete',
            icon: _isDeleting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProgress,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            CircleAvatar(
              radius: 36,
              child: Icon(_goalIcon(_goal.type), size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              _goal.type,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatDate(_goal.startDate)} – '
              '${_formatDate(_goal.endDate)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Column(
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _loadProgress,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              )
            else if (_progress != null) ...[
              Text(
                '${_progress!.progressPercentage.toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: progressValue, minHeight: 12),
              const SizedBox(height: 32),
              _InfoCard(
                title: 'Current',
                value: _formatValue(_progress!.current, _progress!.type),
                icon: Icons.trending_up,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: 'Target',
                value: _formatValue(_progress!.target, _progress!.type),
                icon: Icons.flag_outlined,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: _progress!.isCompleted ? 'Status' : 'Remaining',
                value: _progress!.isCompleted
                    ? 'Completed'
                    : _formatValue(_progress!.remaining, _progress!.type),
                icon: _progress!.isCompleted
                    ? Icons.check_circle_outline
                    : Icons.hourglass_bottom,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
