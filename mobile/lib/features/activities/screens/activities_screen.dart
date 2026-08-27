import 'package:flutter/material.dart';

import '../models/activity_models.dart';
import '../services/activity_service.dart';
import 'add_activity_screen.dart';

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

  void _onFilterChanged(String? type) {
    setState(() {
      _selectedType = type;
    });

    _loadActivities();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: _isLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            )
          : _errorMessage != null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final activities = _activities?.items ?? [];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _buildStatsCard(),
        const SizedBox(height: 20),
        _buildFilter(),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _openAddActivity,
          icon: const Icon(Icons.add),
          label: const Text('Add Activity'),
        ),
        const SizedBox(height: 20),
        Text(
          'Activities',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          _buildEmptyState()
        else
          ...activities.map(_buildActivityCard),
      ],
    );
  }

  Widget _buildStatsCard() {
    final stats = _stats;

    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedType == null ? 'All Activities' : _selectedType!,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.directions_run_rounded,
                    value: stats.totalActivities.toString(),
                    label: 'Activities',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.straighten_rounded,
                    value: '${stats.totalDistance.toStringAsFixed(1)} km',
                    label: 'Distance',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.timer_outlined,
                    value: _formatDuration(stats.totalDurationSeconds),
                    label: 'Duration',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.local_fire_department_outlined,
                    value: '${stats.totalCalories} kcal',
                    label: 'Calories',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: _selectedType == null,
            onSelected: () => _onFilterChanged(null),
          ),
          ..._activityTypes.map(
            (type) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterChip(
                label: type,
                selected: _selectedType == type,
                onSelected: () => _onFilterChanged(type),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ActivityResponse activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(child: Icon(_activityIcon(activity.type))),
        title: Text(
          activity.type,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${_formatDate(activity.startedAt)}\n'
            '${activity.distance.toStringAsFixed(2)} km • '
            '${_formatDuration(activity.durationSeconds)}'
            '${activity.calories != null ? ' • ${activity.calories} kcal' : ''}',
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.directions_run_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedType == null
                  ? 'No activities yet'
                  : 'No $_selectedType activities',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your activities will appear here once you start recording them.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 400,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load activities',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loadActivities,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
