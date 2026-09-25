import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaceUpColors.darkBackground,
      appBar: AppBar(
        backgroundColor: PaceUpColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MILESTONES',
              style: PaceUpTypography.label(
                PaceUpColors.electricGreen,
              ).copyWith(
                fontSize: 9,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'ACHIEVEMENTS',
              style: PaceUpTypography.heading(
                PaceUpColors.darkText,
              ).copyWith(
                fontSize: 23,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isLoading && _achievements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: _AchievementCount(
                unlocked: _achievements
                    .where((achievement) => achievement.isUnlocked)
                    .length,
                total: _achievements.length,
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAchievements,
        color: PaceUpColors.electricGreen,
        backgroundColor: PaceUpColors.darkPanel,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: [
          _buildLoadingHero(),
          const SizedBox(height: 24),
          ...List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: _AchievementSkeleton(),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: PaceUpColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 44,
                  color: PaceUpColors.danger,
                ),
                const SizedBox(height: 16),
                Text(
                  'ACHIEVEMENTS UNAVAILABLE',
                  textAlign: TextAlign.center,
                  style: PaceUpTypography.heading(
                    PaceUpColors.darkText,
                  ).copyWith(fontSize: 21),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: PaceUpTypography.body(
                    PaceUpColors.darkMuted,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _loadAchievements,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PaceUpColors.electricGreen,
                    side: BorderSide(
                      color: PaceUpColors.electricGreen.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    'TRY AGAIN',
                    style: PaceUpTypography.label(
                      PaceUpColors.electricGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_achievements.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.emoji_events_outlined,
            size: 56,
            color: PaceUpColors.darkMuted,
          ),
          const SizedBox(height: 18),
          Text(
            'NO ACHIEVEMENTS YET',
            textAlign: TextAlign.center,
            style: PaceUpTypography.heading(
              PaceUpColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete activities and keep training to start unlocking milestones.',
            textAlign: TextAlign.center,
            style: PaceUpTypography.body(
              PaceUpColors.darkMuted,
            ),
          ),
        ],
      );
    }

    final unlockedCount = _achievements
        .where((achievement) => achievement.isUnlocked)
        .length;

    final totalCount = _achievements.length;

    final lockedCount = totalCount - unlockedCount;

    final progress = totalCount == 0
        ? 0.0
        : unlockedCount / totalCount;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        _AchievementHero(
          unlockedCount: unlockedCount,
          lockedCount: lockedCount,
          totalCount: totalCount,
          progress: progress,
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Text(
              'ALL MILESTONES',
              style: PaceUpTypography.sectionTitle(
                PaceUpColors.darkMuted,
              ),
            ),
            const Spacer(),
            Text(
              '$totalCount TOTAL',
              style: PaceUpTypography.label(
                PaceUpColors.darkMuted,
              ).copyWith(fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._achievements.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AchievementCard(
              achievement: entry.value,
              index: entry.key,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingHero() {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: PaceUpColors.electricGreen,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

class _AchievementCount extends StatelessWidget {
  final int unlocked;
  final int total;

  const _AchievementCount({
    required this.unlocked,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: PaceUpColors.electricGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: PaceUpColors.electricGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        '$unlocked/$total',
        style: PaceUpTypography.label(
          PaceUpColors.electricGreen,
        ).copyWith(fontSize: 10),
      ),
    );
  }
}

class _AchievementHero extends StatelessWidget {
  final int unlockedCount;
  final int lockedCount;
  final int totalCount;
  final double progress;

  const _AchievementHero({
    required this.unlockedCount,
    required this.lockedCount,
    required this.totalCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PaceUpColors.electricGreen.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: PaceUpColors.electricGreen.withValues(alpha: 0.05),
            blurRadius: 26,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: PaceUpColors.electricGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: PaceUpColors.electricGreen.withValues(
                      alpha: 0.28,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: PaceUpColors.electricGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ATHLETE MILESTONES',
                    style: PaceUpTypography.label(
                      PaceUpColors.electricGreen,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'KEEP PUSHING.',
                    style: PaceUpTypography.heading(
                      PaceUpColors.darkText,
                    ).copyWith(fontSize: 22),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$unlockedCount',
                style: PaceUpTypography.heroMetric(
                  PaceUpColors.electricGreen,
                ).copyWith(
                  fontSize: 62,
                  height: 0.9,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 8,
                  bottom: 7,
                ),
                child: Text(
                  '/ $totalCount',
                  style: PaceUpTypography.heading(
                    PaceUpColors.darkMuted,
                  ).copyWith(fontSize: 20),
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: PaceUpTypography.largeMetric(
                  PaceUpColors.darkText,
                ).copyWith(fontSize: 30),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: PaceUpColors.darkBorder,
                  color: PaceUpColors.electricGreen,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$unlockedCount UNLOCKED',
                style: PaceUpTypography.label(
                  PaceUpColors.electricGreen,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 3,
                width: 3,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: PaceUpColors.darkMuted,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$lockedCount REMAINING',
                style: PaceUpTypography.label(
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

class _AchievementCard extends StatelessWidget {
  final AchievementResponse achievement;
  final int index;

  const _AchievementCard({
    required this.achievement,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    final accent = isUnlocked
        ? PaceUpColors.electricGreen
        : PaceUpColors.electricCyan;

    final progress = achievement.requirementValue <= 0
        ? 0.0
        : (achievement.currentProgress / achievement.requirementValue)
            .clamp(0.0, 1.0)
            .toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: 300 + (index * 60).clamp(0, 300),
      ),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PaceUpColors.darkPanel,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isUnlocked
                ? PaceUpColors.electricGreen.withValues(alpha: 0.35)
                : PaceUpColors.darkBorder,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: PaceUpColors.electricGreen.withValues(
                      alpha: 0.045,
                    ),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AchievementIcon(
              icon: _getIcon(achievement.icon),
              accent: accent,
              isUnlocked: isUnlocked,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          achievement.name,
                          style: PaceUpTypography.bodyMedium(
                            PaceUpColors.darkText,
                          ).copyWith(
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isUnlocked
                            ? Icons.check_circle_rounded
                            : Icons.lock_outline_rounded,
                        color: isUnlocked
                            ? PaceUpColors.electricGreen
                            : PaceUpColors.darkMuted,
                        size: 17,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    achievement.description,
                    style: PaceUpTypography.body(
                      PaceUpColors.darkMuted,
                    ).copyWith(
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _requirementText(achievement),
                      style: PaceUpTypography.label(accent).copyWith(
                        fontSize: 8.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isUnlocked)
                    Row(
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 15,
                          color: PaceUpColors.electricGreen,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'UNLOCKED',
                          style: PaceUpTypography.label(
                            PaceUpColors.electricGreen,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _progressText(achievement),
                            style: PaceUpTypography.bodyMedium(
                              PaceUpColors.darkText,
                            ).copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: PaceUpTypography.label(accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 5,
                            backgroundColor: PaceUpColors.darkBorder,
                            color: accent,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'directions_run':
        return Icons.directions_run_rounded;
      case 'looks_5':
        return Icons.looks_5_rounded;
      case 'looks_10':
        return Icons.emoji_events_rounded;
      case 'route':
        return Icons.route_rounded;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'timer':
        return Icons.timer_outlined;
      case 'calendar_today':
        return Icons.calendar_today_outlined;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  String _requirementText(AchievementResponse achievement) {
    switch (achievement.requirementType) {
      case 'ACTIVITY_COUNT':
        return '${achievement.requirementValue.toInt()} ACTIVITIES';

      case 'TOTAL_DISTANCE_KM':
        return '${achievement.requirementValue.toStringAsFixed(0)} KM TOTAL DISTANCE';

      case 'ACTIVITY_DURATION_MINUTES':
        return '${achievement.requirementValue.toInt()} MINUTE ACTIVITY';

      default:
        return 'REQUIREMENT: ${achievement.requirementValue}';
    }
  }

  String _progressText(AchievementResponse achievement) {
    switch (achievement.requirementType) {
      case 'ACTIVITY_COUNT':
        return '${achievement.currentProgress.toInt()} / '
            '${achievement.requirementValue.toInt()}';

      case 'TOTAL_DISTANCE_KM':
        return '${achievement.currentProgress.toStringAsFixed(1)} / '
            '${achievement.requirementValue.toStringAsFixed(0)} KM';

      case 'ACTIVITY_DURATION_MINUTES':
        return '${achievement.currentProgress.toStringAsFixed(0)} / '
            '${achievement.requirementValue.toInt()} MIN';

      default:
        return '${achievement.currentProgress} / '
            '${achievement.requirementValue}';
    }
  }
}

class _AchievementIcon extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final bool isUnlocked;

  const _AchievementIcon({
    required this.icon,
    required this.accent,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: accent.withValues(
          alpha: isUnlocked ? 0.13 : 0.07,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(
            alpha: isUnlocked ? 0.3 : 0.12,
          ),
        ),
      ),
      child: Icon(
        icon,
        color: accent.withValues(
          alpha: isUnlocked ? 1.0 : 0.65,
        ),
        size: 25,
      ),
    );
  }
}

class _AchievementSkeleton extends StatelessWidget {
  const _AchievementSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanelSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 12,
                  width: 150,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  height: 9,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}