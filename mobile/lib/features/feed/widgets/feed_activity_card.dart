import 'package:flutter/material.dart';

import '../models/feed_models.dart';

class FeedActivityCard extends StatelessWidget {
  final FeedActivityResponse activity;
  final VoidCallback? onTap;

  const FeedActivityCard({
    super.key,
    required this.activity,
    this.onTap,
  });

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
      case 'biking':
        return Icons.directions_bike_rounded;

      case 'hike':
      case 'hiking':
        return Icons.hiking_rounded;

      case 'swim':
      case 'swimming':
        return Icons.pool_rounded;

      default:
        return Icons.fitness_center_rounded;
    }
  }

  String _formatActivityType(String type) {
    if (type.isEmpty) {
      return 'Activity';
    }

    return type[0].toUpperCase() + type.substring(1).toLowerCase();
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m';
  }

  String _formatTime(DateTime date) {
    final difference = DateTime.now().difference(date.toLocal());

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ProfileAvatar(
                    displayName: activity.displayName,
                    imageUrl: activity.profileImageUrl,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${activity.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatTime(activity.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    child: Icon(_activityIcon(activity.type)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatActivityType(activity.type),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Distance',
                      value: '${activity.distance.toStringAsFixed(1)} km',
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Duration',
                      value: _formatDuration(activity.durationSeconds),
                    ),
                  ),
                  if (activity.calories != null)
                    Expanded(
                      child: _Metric(
                        label: 'Calories',
                        value: '${activity.calories} kcal',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String displayName;
  final String? imageUrl;

  const _ProfileAvatar({
    required this.displayName,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initial = displayName.trim().isEmpty
        ? '?'
        : displayName.trim()[0].toUpperCase();

    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: 24,
        child: Text(
          initial,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundImage: NetworkImage(imageUrl!),
      onBackgroundImageError: (_, _) {},
      child: const SizedBox.shrink(),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}