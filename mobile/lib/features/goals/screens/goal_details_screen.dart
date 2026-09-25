import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: PaceUpColors.danger.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: PaceUpColors.danger.withValues(alpha: 0.08),
                  blurRadius: 30,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: PaceUpColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: PaceUpColors.danger.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: PaceUpColors.danger,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'DELETE GOAL',
                        style: PaceUpTypography.heading(PaceUpColors.darkText)
                            .copyWith(fontSize: 22, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  'Are you sure you want to delete this goal?',
                  style: PaceUpTypography.body(PaceUpColors.darkText)
                      .copyWith(fontSize: 14, height: 1.5),
                ),

                const SizedBox(height: 8),

                Text(
                  'This action cannot be undone. Your goal and its progress data will be permanently removed.',
                  style: PaceUpTypography.body(PaceUpColors.darkMuted)
                      .copyWith(fontSize: 12, height: 1.5),
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PaceUpColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _goalAccent(_goal.type)
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          _goalIcon(_goal.type),
                          color: _goalAccent(_goal.type),
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_goal.type.toUpperCase()} GOAL',
                              style: PaceUpTypography.label(
                                PaceUpColors.darkMuted,
                              ).copyWith(fontSize: 8),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatValue(_progress?.target ?? 0, _goal.type),
                              style: PaceUpTypography.bodyMedium(
                                PaceUpColors.darkText,
                              ).copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          foregroundColor: PaceUpColors.darkMuted,
                          side: const BorderSide(
                            color: PaceUpColors.darkBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: PaceUpTypography.label(PaceUpColors.darkMuted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          backgroundColor: PaceUpColors.danger,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'DELETE',
                          style: PaceUpTypography.label(Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      SnackBar(
        content: Text(
          message,
          style: PaceUpTypography.body(PaceUpColors.darkText),
        ),
        behavior: SnackBarBehavior.floating,
      ),
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

  Color _goalAccent(String type) {
    switch (type) {
      case 'Distance':
        return PaceUpColors.electricCyan;

      case 'Duration':
        return PaceUpColors.electricGreen;

      case 'Calories':
        return const Color(0xFFFF9F43);

      case 'Activities':
        return const Color(0xFFC084FC);

      default:
        return PaceUpColors.electricGreen;
    }
  }

  String _goalUnit(String type) {
    switch (type) {
      case 'Distance':
        return 'KM';

      case 'Duration':
        return 'TIME';

      case 'Calories':
        return 'KCAL';

      case 'Activities':
        return 'ACTIVITIES';

      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _goalAccent(_goal.type);

    final progressValue = _progress == null
        ? 0.0
        : (_progress!.progressPercentage / 100).clamp(0.0, 1.0).toDouble();

    final progressPercentage = _progress?.progressPercentage ?? 0.0;

    return Scaffold(
      backgroundColor: PaceUpColors.darkBackground,
      appBar: AppBar(
        backgroundColor: PaceUpColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'GOAL DETAILS',
          style: PaceUpTypography.heading(PaceUpColors.darkText)
              .copyWith(fontSize: 22, letterSpacing: 0.4),
        ),
        actions: [
          IconButton(
            onPressed: _isDeleting ? null : _edit,
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, color: PaceUpColors.darkText),
          ),
          IconButton(
            onPressed: _isDeleting ? null : _delete,
            tooltip: 'Delete',
            icon: _isDeleting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PaceUpColors.danger,
                    ),
                  )
                : const Icon(Icons.delete_outline, color: PaceUpColors.danger),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: accent,
        backgroundColor: PaceUpColors.darkPanel,
        onRefresh: _loadProgress,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _GoalHero(
              goal: _goal,
              accent: accent,
              progressValue: progressValue,
              progressPercentage: progressPercentage,
              icon: _goalIcon(_goal.type),
              unit: _goalUnit(_goal.type),
              formatDate: _formatDate,
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              _LoadingState(accent: accent)
            else if (_errorMessage != null)
              _ErrorState(
                message: _errorMessage!,
                accent: accent,
                onRetry: _loadProgress,
              )
            else if (_progress != null) ...[
              _ProgressOverview(
                progress: _progress!,
                accent: accent,
                progressValue: progressValue,
                formatValue: _formatValue,
              ),
              const SizedBox(height: 20),
              _ProgressMetrics(
                progress: _progress!,
                accent: accent,
                formatValue: _formatValue,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalHero extends StatelessWidget {
  final GoalResponse goal;
  final Color accent;
  final double progressValue;
  final double progressPercentage;
  final IconData icon;
  final String unit;
  final String Function(DateTime) formatDate;

  const _GoalHero({
    required this.goal,
    required this.accent,
    required this.progressValue,
    required this.progressPercentage,
    required this.icon,
    required this.unit,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = progressPercentage >= 100;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.28)),
                ),
                child: Icon(icon, color: accent, size: 27),
              ),
              const Spacer(),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: PaceUpColors.electricGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: PaceUpColors.electricGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: PaceUpColors.electricGreen,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'COMPLETED',
                        style: PaceUpTypography.label(
                          PaceUpColors.electricGreen,
                        ).copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('TRAINING GOAL', style: PaceUpTypography.sectionTitle(accent)),
          const SizedBox(height: 4),
          Text(
            goal.type.toUpperCase(),
            style: PaceUpTypography.heading(PaceUpColors.darkText)
                .copyWith(fontSize: 32, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatDate(goal.startDate)}  —  ${formatDate(goal.endDate)}',
            style: PaceUpTypography.body(PaceUpColors.darkMuted),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                progressPercentage.toStringAsFixed(1),
                style: PaceUpTypography.heroMetric(accent)
                    .copyWith(fontSize: 58, height: 0.95),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '%',
                  style: PaceUpTypography.heading(accent)
                      .copyWith(fontSize: 24),
                ),
              ),
              const Spacer(),
              Text(unit, style: PaceUpTypography.label(PaceUpColors.darkMuted)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
              backgroundColor: PaceUpColors.darkBorder,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  final GoalProgressResponse progress;
  final Color accent;
  final double progressValue;
  final String Function(double, String) formatValue;

  const _ProgressOverview({
    required this.progress,
    required this.accent,
    required this.progressValue,
    required this.formatValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanelSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PaceUpColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROGRESS OVERVIEW',
            style: PaceUpTypography.sectionTitle(PaceUpColors.darkMuted),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatValue(progress.current, progress.type),
                style: PaceUpTypography.largeMetric(PaceUpColors.darkText)
                    .copyWith(fontSize: 38),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'CURRENT',
                  style: PaceUpTypography.label(PaceUpColors.darkMuted)
                      .copyWith(fontSize: 9),
                ),
              ),
              const Spacer(),
              Text(
                formatValue(progress.target, progress.type),
                style: PaceUpTypography.bodyMedium(accent),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progressValue),
              duration: const Duration(milliseconds: 700),
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
          const SizedBox(height: 12),
          Text(
            progress.isCompleted
                ? 'Target reached. Keep the momentum going.'
                : '${progressPercentageText(progress.progressPercentage)}% of your target completed.',
            style: PaceUpTypography.body(PaceUpColors.darkMuted),
          ),
        ],
      ),
    );
  }

  String progressPercentageText(double value) {
    return value.toStringAsFixed(1);
  }
}

class _ProgressMetrics extends StatelessWidget {
  final GoalProgressResponse progress;
  final Color accent;
  final String Function(double, String) formatValue;

  const _ProgressMetrics({
    required this.progress,
    required this.accent,
    required this.formatValue,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress.isCompleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GOAL METRICS',
          style: PaceUpTypography.sectionTitle(PaceUpColors.darkMuted),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'CURRENT',
                value: formatValue(progress.current, progress.type),
                icon: Icons.trending_up_rounded,
                accent: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'TARGET',
                value: formatValue(progress.target, progress.type),
                icon: Icons.flag_outlined,
                accent: PaceUpColors.darkMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MetricCard(
          title: isCompleted ? 'STATUS' : 'REMAINING',
          value: isCompleted
              ? 'COMPLETED'
              : formatValue(progress.remaining, progress.type),
          icon: isCompleted
              ? Icons.check_circle_rounded
              : Icons.hourglass_bottom_rounded,
          accent: isCompleted
              ? PaceUpColors.electricGreen
              : PaceUpColors.electricCyan,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final bool fullWidth;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: fullWidth ? const BoxConstraints(minHeight: 76) : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaceUpColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accent, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PaceUpTypography.label(PaceUpColors.darkMuted)
                      .copyWith(fontSize: 8),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PaceUpTypography.bodyMedium(PaceUpColors.darkText)
                      .copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final Color accent;

  const _LoadingState({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PaceUpColors.darkBorder),
      ),
      child: Center(
        child: CircularProgressIndicator(color: accent, strokeWidth: 2.5),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Color accent;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.accent,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PaceUpColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: PaceUpColors.danger,
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            'COULD NOT LOAD GOAL',
            style: PaceUpTypography.heading(PaceUpColors.darkText)
                .copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: PaceUpTypography.body(PaceUpColors.darkMuted),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent.withValues(alpha: 0.4)),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: Text('TRY AGAIN', style: PaceUpTypography.label(accent)),
          ),
        ],
      ),
    );
  }
}
