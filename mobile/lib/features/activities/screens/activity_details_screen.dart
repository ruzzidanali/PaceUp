import 'package:flutter/material.dart';

import '../../auth/services/auth_service.dart';
import '../../kudos/models/kudos_models.dart';
import '../../kudos/services/kudos_service.dart';
import '../models/activity_models.dart';
import '../services/activity_service.dart';
import 'add_activity_screen.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final ActivityResponse activity;

  const ActivityDetailsScreen({
    super.key,
    required this.activity,
  });

  @override
  State<ActivityDetailsScreen> createState() =>
      _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  late final ActivityService _activityService;
  late final KudosService _kudosService;

  late ActivityResponse _activity;

  KudosResponse? _kudos;

  bool _isDeleting = false;
  bool _isLoadingKudos = true;
  bool _isUpdatingKudos = false;
  bool _isOwnActivity = false;

  @override
  void initState() {
    super.initState();

    _activity = widget.activity;

    _activityService = ActivityService();
    _kudosService = KudosService();

    _loadActivityState();
  }

  @override
  void dispose() {
    _activityService.dispose();
    _kudosService.dispose();

    super.dispose();
  }

  Future<void> _loadActivityState() async {
    try {
      final authService = AuthService();

      try {
        final currentUser = await authService.getCurrentUser();

        if (!mounted) {
          return;
        }

        setState(() {
          _isOwnActivity = currentUser.id == _activity.userId;
        });
      } finally {
        authService.dispose();
      }

      if (_isOwnActivity) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoadingKudos = false;
        });

        return;
      }

      final kudos = await _kudosService.getKudos(_activity.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _kudos = kudos;
        _isLoadingKudos = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingKudos = false;
      });
    }
  }

  Future<void> _editActivity() async {
    final updated = await Navigator.of(context).push<ActivityResponse>(
      MaterialPageRoute(
        builder: (_) => AddActivityScreen(
          activity: _activity,
        ),
      ),
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
        content: const Text(
          'This activity will be permanently deleted.',
        ),
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
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleKudos() async {
    final kudos = _kudos;

    if (kudos == null || _isUpdatingKudos) {
      return;
    }

    setState(() {
      _isUpdatingKudos = true;
    });

    try {
      final updated = kudos.hasGivenKudos
          ? await _kudosService.removeKudos(_activity.id)
          : await _kudosService.giveKudos(_activity.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _kudos = updated;
        _isUpdatingKudos = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingKudos = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildKudosCard() {
    if (_isLoadingKudos) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final kudos = _kudos;

    if (kudos == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    kudos.hasGivenKudos
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${kudos.kudosCount} Kudos',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed:
                  _isUpdatingKudos ? null : _toggleKudos,
              icon: _isUpdatingKudos
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      kudos.hasGivenKudos
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
              label: Text(
                kudos.hasGivenKudos
                    ? 'Kudos Given'
                    : 'Give Kudos',
              ),
            ),
          ],
        ),
      ),
    );
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
          if (_isOwnActivity) ...[
            IconButton(
              onPressed:
                  _isDeleting ? null : _editActivity,
              tooltip: 'Edit',
              icon: const Icon(
                Icons.edit_outlined,
              ),
            ),
            IconButton(
              onPressed:
                  _isDeleting ? null : _deleteActivity,
              tooltip: 'Delete',
              icon: _isDeleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.delete_outline,
                    ),
            ),
          ],
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
                    child: Icon(
                      _activityIcon(activity.type),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    activity.type,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDateTime(activity.startedAt),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
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
                  value:
                      '${activity.distance.toStringAsFixed(2)} km',
                  label: 'Distance',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.timer_outlined,
                  value: _formatDuration(
                    activity.durationSeconds,
                  ),
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

          // Social interaction for activities owned by other users.
          if (!_isOwnActivity) ...[
            const SizedBox(height: 24),
            _buildKudosCard(),
          ],

          if (_isOwnActivity) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed:
                  _isDeleting ? null : _editActivity,
              icon: const Icon(
                Icons.edit_outlined,
              ),
              label: const Text(
                'Edit Activity',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed:
                  _isDeleting ? null : _deleteActivity,
              icon: const Icon(
                Icons.delete_outline,
              ),
              label: const Text(
                'Delete Activity',
              ),
            ),
          ],
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
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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