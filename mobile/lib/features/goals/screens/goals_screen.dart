import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AddGoalScreen(),
      ),
    );

    if (created == true && mounted) {
      await _loadGoals();
    }
  }

  Future<void> _openGoal(GoalResponse goal) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GoalDetailsScreen(goal: goal),
      ),
    );

    if (changed == true && mounted) {
      await _loadGoals();
    }
  }

  double get _averageProgress {
    final available = _goals
        .map((goal) => _progress[goal.id])
        .whereType<GoalProgressResponse>()
        .toList();

    if (available.isEmpty) {
      return 0;
    }

    final total = available.fold<double>(
      0,
      (sum, progress) => sum + progress.progressPercentage,
    );

    return (total / available.length).clamp(0, 100);
  }

  int get _completedGoals {
    return _goals.where((goal) {
      return _progress[goal.id]?.isCompleted == true;
    }).length;
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

  Color _goalAccent(String type) {
    switch (type) {
      case 'Distance':
        return PaceUpColors.electricGreen;

      case 'Duration':
        return PaceUpColors.electricCyan;

      case 'Calories':
        return PaceUpColors.danger;

      case 'Activities':
        return PaceUpColors.electricGreen;

      default:
        return PaceUpColors.electricCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaceUpColors.darkBackground,
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton(
              onPressed: _addGoal,
              backgroundColor: PaceUpColors.electricGreen,
              foregroundColor: PaceUpColors.greenInk,
              elevation: 4,
              child: const Icon(Icons.add_rounded),
            ),
      body: RefreshIndicator(
        color: PaceUpColors.electricGreen,
        backgroundColor: PaceUpColors.darkPanel,
        onRefresh: _loadGoals,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 70, 20, 40),
        children: [
          _buildLoadingHeader(),
          const SizedBox(height: 24),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildLoadingCard(),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 40),
        children: [
          _buildHeader(),
          const SizedBox(height: 70),
          _buildStateIcon(
            icon: Icons.error_outline_rounded,
            color: PaceUpColors.danger,
          ),
          const SizedBox(height: 20),
          Text(
            'GOALS UNAVAILABLE',
            textAlign: TextAlign.center,
            style: PaceUpTypography.sectionTitle(
              PaceUpColors.danger,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: PaceUpTypography.body(
              PaceUpColors.darkMuted,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              height: 46,
              child: FilledButton.icon(
                onPressed: _loadGoals,
                style: FilledButton.styleFrom(
                  backgroundColor: PaceUpColors.electricGreen,
                  foregroundColor: PaceUpColors.greenInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  'TRY AGAIN',
                  style: PaceUpTypography.label(
                    PaceUpColors.greenInk,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_goals.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
        children: [
          _buildHeader(),
          const SizedBox(height: 70),
          _buildStateIcon(
            icon: Icons.flag_outlined,
            color: PaceUpColors.electricGreen,
          ),
          const SizedBox(height: 22),
          Text(
            'NO GOALS YET',
            textAlign: TextAlign.center,
            style: PaceUpTypography.heading(
              PaceUpColors.darkText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Set a target and give your next training block a clear direction.',
            textAlign: TextAlign.center,
            style: PaceUpTypography.body(
              PaceUpColors.darkMuted,
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _addGoal,
              style: FilledButton.styleFrom(
                backgroundColor: PaceUpColors.electricGreen,
                foregroundColor: PaceUpColors.greenInk,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'CREATE GOAL',
                style: PaceUpTypography.label(
                  PaceUpColors.greenInk,
                ).copyWith(
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        _buildHeader(),
        const SizedBox(height: 22),
        _buildOverview(),
        const SizedBox(height: 28),
        Row(
          children: [
            Text(
              'YOUR GOALS',
              style: PaceUpTypography.sectionTitle(
                PaceUpColors.darkMuted,
              ),
            ),
            const Spacer(),
            Text(
              '${_goals.length} TOTAL',
              style: PaceUpTypography.label(
                PaceUpColors.darkMuted,
              ).copyWith(
                fontSize: 8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._goals.map(
          (goal) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GoalCard(
              goal: goal,
              progress: _progress[goal.id],
              icon: _goalIcon(goal.type),
              accent: _goalAccent(goal.type),
              targetLabel: _formatTarget(goal),
              startDate: _formatDate(goal.startDate),
              endDate: _formatDate(goal.endDate),
              onTap: () => _openGoal(goal),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          'GOALS',
          style: PaceUpTypography.display(
            PaceUpColors.darkText,
          ).copyWith(
            fontSize: 42,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Set the target. Track the progress. Keep moving.',
          style: PaceUpTypography.body(
            PaceUpColors.darkMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 75,
          height: 10,
          decoration: BoxDecoration(
            color: PaceUpColors.darkPanel,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 120,
          height: 38,
          decoration: BoxDecoration(
            color: PaceUpColors.darkPanel,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 260,
          height: 12,
          decoration: BoxDecoration(
            color: PaceUpColors.darkPanel,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }

  Widget _buildOverview() {
    final progress = _averageProgress / 100;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'GOAL PROGRESS',
                style: PaceUpTypography.sectionTitle(
                  PaceUpColors.darkMuted,
                ),
              ),
              const Spacer(),
              Text(
                '${_averageProgress.toStringAsFixed(0)}%',
                style: PaceUpTypography.largeMetric(
                  PaceUpColors.electricGreen,
                ).copyWith(
                  fontSize: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: PaceUpColors.darkPanelSecondary,
              valueColor: const AlwaysStoppedAnimation(
                PaceUpColors.electricGreen,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _OverviewStat(
                value: '${_goals.length}',
                label: 'ACTIVE',
              ),
              const SizedBox(width: 28),
              _OverviewStat(
                value: '$_completedGoals',
                label: 'COMPLETED',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateIcon({
    required IconData icon,
    required Color color,
  }) {
    return Center(
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.30),
          ),
        ),
        child: Icon(
          icon,
          size: 36,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 130,
              height: 16,
              decoration: BoxDecoration(
                color: PaceUpColors.darkPanelSecondary,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 180,
              height: 28,
              decoration: BoxDecoration(
                color: PaceUpColors.darkPanelSecondary,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: PaceUpColors.darkPanelSecondary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final String value;
  final String label;

  const _OverviewStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value,
          style: PaceUpTypography.largeMetric(
            PaceUpColors.darkText,
          ).copyWith(
            fontSize: 24,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: PaceUpTypography.label(
            PaceUpColors.darkMuted,
          ).copyWith(
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalResponse goal;
  final GoalProgressResponse? progress;
  final IconData icon;
  final Color accent;
  final String targetLabel;
  final String startDate;
  final String endDate;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.progress,
    required this.icon,
    required this.accent,
    required this.targetLabel,
    required this.startDate,
    required this.endDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercentage =
        progress?.progressPercentage.clamp(0, 100) ?? 0;
    final progressValue = progressPercentage / 100;
    final isCompleted = progress?.isCompleted == true;

    return Material(
      color: PaceUpColors.darkPanel,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCompleted
                  ? PaceUpColors.electricGreen.withValues(alpha: 0.45)
                  : PaceUpColors.darkBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: accent,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.type.toUpperCase(),
                          style: PaceUpTypography.sectionTitle(
                            accent,
                          ).copyWith(
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          targetLabel,
                          style: PaceUpTypography.heading(
                            PaceUpColors.darkText,
                          ).copyWith(
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: isCompleted
                        ? PaceUpColors.electricGreen
                        : PaceUpColors.darkMuted,
                    size: isCompleted ? 22 : 14,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    isCompleted
                        ? 'COMPLETED'
                        : progress == null
                            ? 'PROGRESS UNAVAILABLE'
                            : '${progressPercentage.toStringAsFixed(0)}% COMPLETE',
                    style: PaceUpTypography.label(
                      isCompleted
                          ? PaceUpColors.electricGreen
                          : PaceUpColors.darkMuted,
                    ).copyWith(
                      fontSize: 8,
                    ),
                  ),
                  const Spacer(),
                  if (progress != null && !isCompleted)
                    Text(
                      '${progress!.remaining.toStringAsFixed(1)} remaining',
                      style: PaceUpTypography.body(
                        PaceUpColors.darkMuted,
                      ).copyWith(
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 7,
                  backgroundColor:
                      PaceUpColors.darkPanelSecondary,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted
                        ? PaceUpColors.electricGreen
                        : accent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: PaceUpColors.darkMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$startDate  —  $endDate',
                    style: PaceUpTypography.body(
                      PaceUpColors.darkMuted,
                    ).copyWith(
                      fontSize: 10,
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