import 'package:flutter/material.dart';

import '../models/activity_models.dart';
import '../services/activity_service.dart';
import 'add_activity_screen.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final ActivityResponse activity;

  const ActivityDetailsScreen({super.key, required this.activity});

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  late final ActivityService _activityService;

  late ActivityResponse _activity;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _activity = widget.activity;
    _activityService = ActivityService();
  }

  @override
  void dispose() {
    _activityService.dispose();
    super.dispose();
  }

  Future<void> _editActivity() async {
    final updated = await Navigator.of(context).push<ActivityResponse>(
      MaterialPageRoute(builder: (_) => AddActivityScreen(activity: _activity)),
    );

    if (updated != null && mounted) {
      setState(() {
        _activity = updated;
      });
    }
  }

  Future<void> _deleteActivity() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity?'),
        content: const Text('This activity will be permanently deleted.'),
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
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _activityService.deleteActivity(_activity.id);

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }

    return '${minutes}m ${seconds}s';
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'Run':
        return Icons.directions_run;
      case 'Ride':
        return Icons.directions_bike;
      case 'Walk':
        return Icons.directions_walk;
      case 'Hike':
        return Icons.terrain;
      case 'Swim':
        return Icons.pool;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = _activity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Details'),
        actions: [
          IconButton(
            onPressed: _isDeleting ? null : _editActivity,
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _isDeleting ? null : _deleteActivity,
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    child: Icon(_activityIcon(activity.type), size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    activity.type,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDateTime(activity.startedAt),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.straighten_rounded,
                  value: '${activity.distance.toStringAsFixed(2)} km',
                  label: 'Distance',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.timer_outlined,
                  value: _formatDuration(activity.durationSeconds),
                  label: 'Duration',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MetricCard(
            icon: Icons.local_fire_department_outlined,
            value: activity.calories == null
                ? '—'
                : '${activity.calories} kcal',
            label: 'Calories',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isDeleting ? null : _editActivity,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Activity'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isDeleting ? null : _deleteActivity,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Activity'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}
