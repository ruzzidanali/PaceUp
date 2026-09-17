import 'package:flutter/material.dart';

import '../models/achievement_models.dart';
import '../services/achievement_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementService _achievementService = AchievementService();

  List<AchievementResponse> _achievements = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final achievements = await _achievementService.getAchievements();

      if (!mounted) {
        return;
      }

      setState(() {
        _achievements = achievements;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Failed to load achievements.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadAchievements,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_achievements.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAchievements,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(child: Text('No achievements available.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAchievements,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _achievements.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _AchievementCard(achievement: _achievements[index]);
        },
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementResponse achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    final progress = achievement.requirementValue <= 0
        ? 0.0
        : (achievement.currentProgress / achievement.requirementValue).clamp(
            0.0,
            1.0,
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 28, child: Icon(_getIcon(achievement.icon))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(achievement.description),
                  const SizedBox(height: 8),
                  Text(_requirementText(achievement)),
                  const SizedBox(height: 12),
                  if (isUnlocked)
                    const Row(
                      children: [
                        Icon(Icons.check_circle, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Unlocked',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _progressText(achievement),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(isUnlocked ? Icons.check_circle : Icons.lock_outline),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'directions_run':
        return Icons.directions_run;
      case 'looks_5':
        return Icons.looks_5;
      case 'looks_10':
        return Icons.emoji_events;
      case 'route':
        return Icons.route;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'timer':
        return Icons.timer;
      case 'calendar_today':
        return Icons.calendar_today;
      default:
        return Icons.emoji_events;
    }
  }

  String _requirementText(AchievementResponse achievement) {
    switch (achievement.requirementType) {
      case 'ACTIVITY_COUNT':
        return '${achievement.requirementValue.toInt()} activities';

      case 'TOTAL_DISTANCE_KM':
        return '${achievement.requirementValue.toStringAsFixed(0)} km total distance';

      case 'ACTIVITY_DURATION_MINUTES':
        return '${achievement.requirementValue.toInt()} minute activity';

      default:
        return 'Requirement: ${achievement.requirementValue}';
    }
  }

  String _progressText(AchievementResponse achievement) {
    switch (achievement.requirementType) {
      case 'ACTIVITY_COUNT':
        return '${achievement.currentProgress.toInt()} / '
            '${achievement.requirementValue.toInt()}';

      case 'TOTAL_DISTANCE_KM':
        return '${achievement.currentProgress.toStringAsFixed(1)} / '
            '${achievement.requirementValue.toStringAsFixed(0)} km';

      case 'ACTIVITY_DURATION_MINUTES':
        return '${achievement.currentProgress.toStringAsFixed(0)} / '
            '${achievement.requirementValue.toInt()} min';

      default:
        return '${achievement.currentProgress} / '
            '${achievement.requirementValue}';
    }
  }
}
