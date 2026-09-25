import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/challenge_models.dart';
import '../services/challenge_service.dart';
import '../../auth/services/auth_state.dart';

class ChallengeDetailsScreen extends StatefulWidget {
  final ChallengeResponse challenge;
  final ChallengeService challengeService;
  final AuthController authController;

  const ChallengeDetailsScreen({
    super.key,
    required this.challenge,
    required this.challengeService,
    required this.authController,
  });

  @override
  State<ChallengeDetailsScreen> createState() => _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState extends State<ChallengeDetailsScreen> {
  ChallengeProgressResponse? _progress;
  ChallengeLeaderboardResponse? _leaderboard;

  bool _isLoading = true;
  bool _isJoining = false;
  bool _isDeleting = false;
  String? _errorMessage;

  bool get _isChallengeCreator {
    return widget.challenge.createdByUserId ==
        widget.authController.state.user?.id;
  }

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final progress = await widget.challengeService.getProgress(
        widget.challenge.id,
      );

      final leaderboard = await widget.challengeService.getLeaderboard(
        widget.challenge.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _progress = progress;
        _leaderboard = leaderboard;
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

  Future<void> _join() async {
    setState(() {
      _isJoining = true;
    });

    try {
      await widget.challengeService.joinChallenge(widget.challenge.id);

      if (!mounted) {
        return;
      }

      _showMessage('Joined challenge successfully.');
      await _loadDetails();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _leave() async {
    final confirmed = await _showLeaveConfirmation();

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      await widget.challengeService.leaveChallenge(widget.challenge.id);

      if (!mounted) {
        return;
      }

      _showMessage('Left challenge.');
      await _loadDetails();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<bool?> _showLeaveConfirmation() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: PaceUpColors.electricCyan.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: PaceUpColors.electricCyan.withValues(alpha: 0.08),
                  blurRadius: 28,
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
                        color: PaceUpColors.electricCyan.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: PaceUpColors.electricCyan.withValues(
                            alpha: 0.22,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: PaceUpColors.electricCyan,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'LEAVE CHALLENGE',
                        style: PaceUpTypography.heading(PaceUpColors.darkText)
                            .copyWith(fontSize: 24, letterSpacing: 0.2),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Text(
                  'Are you sure you want to leave this challenge?',
                  style: PaceUpTypography.body(PaceUpColors.darkText),
                ),

                const SizedBox(height: 8),

                Text(
                  'You will no longer be able to contribute to this challenge unless you join again.',
                  style: PaceUpTypography.body(PaceUpColors.darkMuted),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PaceUpColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: PaceUpColors.electricCyan.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: PaceUpColors.electricCyan.withValues(
                              alpha: 0.14,
                            ),
                          ),
                        ),
                        child: Icon(
                          _challengeIcon(widget.challenge.type),
                          color: PaceUpColors.electricCyan,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHALLENGE',
                              style: PaceUpTypography.label(
                                PaceUpColors.darkMuted,
                              ).copyWith(fontSize: 8, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.challenge.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PaceUpTypography.bodyMedium(
                                PaceUpColors.darkText,
                              ).copyWith(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PaceUpColors.darkMuted,
                            side: const BorderSide(
                              color: PaceUpColors.darkBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'CANCEL',
                            style: PaceUpTypography.label(
                              PaceUpColors.darkMuted,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: PaceUpColors.electricGreen,
                            foregroundColor: PaceUpColors.greenInk,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'LEAVE',
                            style: PaceUpTypography.label(
                              PaceUpColors.greenInk,
                            ),
                          ),
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
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: PaceUpColors.danger.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: PaceUpColors.danger.withValues(alpha: 0.10),
                  blurRadius: 28,
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
                        color: PaceUpColors.danger.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: PaceUpColors.danger.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: PaceUpColors.danger,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'DELETE CHALLENGE',
                        style: PaceUpTypography.heading(PaceUpColors.darkText)
                            .copyWith(fontSize: 24, letterSpacing: 0.2),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Text(
                  'Are you sure you want to delete this challenge?',
                  style: PaceUpTypography.body(PaceUpColors.darkText),
                ),

                const SizedBox(height: 8),

                Text(
                  'This action cannot be undone. Your challenge and its participant data will be permanently removed.',
                  style: PaceUpTypography.body(PaceUpColors.darkMuted),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PaceUpColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: PaceUpColors.electricGreen.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: PaceUpColors.electricGreen.withValues(
                              alpha: 0.14,
                            ),
                          ),
                        ),
                        child: Icon(
                          _challengeIcon(widget.challenge.type),
                          color: PaceUpColors.electricGreen,
                          size: 25,
                        ),
                      ),

                      const SizedBox(width: 13),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHALLENGE',
                              style: PaceUpTypography.label(
                                PaceUpColors.darkMuted,
                              ).copyWith(fontSize: 8, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.challenge.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PaceUpTypography.bodyMedium(
                                PaceUpColors.darkText,
                              ).copyWith(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PaceUpColors.darkMuted,
                            side: const BorderSide(
                              color: PaceUpColors.darkBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'CANCEL',
                            style: PaceUpTypography.label(
                              PaceUpColors.darkMuted,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: PaceUpColors.danger,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'DELETE',
                            style: PaceUpTypography.label(Colors.white),
                          ),
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
      await widget.challengeService.deleteChallenge(widget.challenge.id);

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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: PaceUpColors.danger,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _formatValue(String type, double value) {
    switch (type) {
      case 'Distance':
        return '${value.toStringAsFixed(1)} km';
      case 'Duration':
        final minutes = (value / 60).floor();
        final seconds = value.round() % 60;
        return '${minutes}m ${seconds}s';
      case 'Activities':
        return value.toStringAsFixed(0);
      default:
        return value.toStringAsFixed(1);
    }
  }

  String _targetLabel(String type) {
    switch (type) {
      case 'Distance':
        return 'DISTANCE TARGET';
      case 'Duration':
        return 'DURATION TARGET';
      case 'Activities':
        return 'ACTIVITY TARGET';
      default:
        return 'TARGET';
    }
  }

  IconData _challengeIcon(String type) {
    switch (type) {
      case 'Distance':
        return Icons.route_rounded;
      case 'Duration':
        return Icons.timer_outlined;
      case 'Activities':
        return Icons.directions_run_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  bool _isActive() {
    final now = DateTime.now();

    return !now.isBefore(widget.challenge.startDate) &&
        !now.isAfter(widget.challenge.endDate);
  }

  bool _isUpcoming() {
    return DateTime.now().isBefore(widget.challenge.startDate);
  }

  String _status() {
    if (_isActive()) {
      return 'ACTIVE';
    }

    if (_isUpcoming()) {
      return 'UPCOMING';
    }

    return 'ENDED';
  }

  Color _statusColor() {
    if (_isActive()) {
      return PaceUpColors.electricGreen;
    }

    if (_isUpcoming()) {
      return PaceUpColors.electricCyan;
    }

    return PaceUpColors.darkMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaceUpColors.darkBackground,
      appBar: AppBar(
        backgroundColor: PaceUpColors.darkBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 4,
        title: Text(
          'CHALLENGE DETAILS',
          style: PaceUpTypography.sectionTitle(PaceUpColors.electricGreen),
        ),
        actions: [
          if (_isChallengeCreator)
            IconButton(
              onPressed: _isDeleting ? null : _delete,
              tooltip: 'Delete challenge',
              icon: _isDeleting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PaceUpColors.danger,
                      ),
                    )
                  : const Icon(
                      Icons.delete_outline_rounded,
                      color: PaceUpColors.danger,
                    ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetails,
        color: PaceUpColors.electricGreen,
        backgroundColor: PaceUpColors.darkPanel,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
      children: [
        _buildHero(),
        const SizedBox(height: 18),
        if (_progress != null) ...[
          _buildProgress(),
          const SizedBox(height: 16),
        ],
        _buildAction(),
        const SizedBox(height: 30),
        if (_leaderboard != null) _buildLeaderboard(),
      ],
    );
  }

  Widget _buildLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        _LoadingBlock(height: 250, radius: 18),
        const SizedBox(height: 14),
        _LoadingBlock(height: 190, radius: 18),
        const SizedBox(height: 14),
        _LoadingBlock(height: 54, radius: 14),
        const SizedBox(height: 28),
        _LoadingBlock(height: 280, radius: 18),
      ],
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 70),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PaceUpColors.darkPanel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: PaceUpColors.danger.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: PaceUpColors.danger.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  color: PaceUpColors.danger,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'CHALLENGE UNAVAILABLE',
                textAlign: TextAlign.center,
                style: PaceUpTypography.heading(PaceUpColors.darkText),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: PaceUpTypography.body(PaceUpColors.darkMuted),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _loadDetails,
                  style: FilledButton.styleFrom(
                    backgroundColor: PaceUpColors.electricGreen,
                    foregroundColor: PaceUpColors.greenInk,
                  ),
                  child: Text(
                    'TRY AGAIN',
                    style: PaceUpTypography.label(PaceUpColors.greenInk),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    final challenge = widget.challenge;
    final status = _status();
    final statusColor = _statusColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.28)),
        boxShadow: _isActive()
            ? [
                BoxShadow(
                  color: PaceUpColors.electricGreen.withValues(alpha: 0.06),
                  blurRadius: 28,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(
                  _challengeIcon(challenge.type),
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status, style: PaceUpTypography.label(statusColor)),
                    const SizedBox(height: 5),
                    Text(
                      challenge.name,
                      style: PaceUpTypography.heading(PaceUpColors.darkText)
                          .copyWith(fontSize: 28, height: 1.05),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (challenge.description != null &&
              challenge.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              challenge.description!,
              style: PaceUpTypography.body(PaceUpColors.darkMuted),
            ),
          ],
          const SizedBox(height: 20),
          Container(height: 1, color: PaceUpColors.darkBorder),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: _targetLabel(challenge.type),
                  value: _formatValue(challenge.type, challenge.targetValue),
                  accent: statusColor,
                ),
              ),
              Container(width: 1, height: 44, color: PaceUpColors.darkBorder),
              Expanded(
                child: _HeroMetric(
                  label: 'PARTICIPANTS',
                  value: challenge.participantCount.toString(),
                  accent: PaceUpColors.electricCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: PaceUpColors.darkMuted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${_formatDate(challenge.startDate)} → '
                  '${_formatDate(challenge.endDate)}',
                  style: PaceUpTypography.body(PaceUpColors.darkMuted)
                      .copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final progress = _progress!;

    final percentage = (progress.progressPercentage / 100).clamp(0.0, 1.0);

    final completed = progress.isCompleted;
    final accent = completed
        ? PaceUpColors.electricGreen
        : PaceUpColors.electricCyan;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: completed
              ? PaceUpColors.electricGreen.withValues(alpha: 0.30)
              : PaceUpColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'YOUR PROGRESS',
                  style: PaceUpTypography.sectionTitle(accent),
                ),
              ),
              if (completed)
                const Icon(
                  Icons.verified_rounded,
                  color: PaceUpColors.electricGreen,
                  size: 21,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.progressPercentage),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: PaceUpTypography.largeMetric(PaceUpColors.darkText)
                        .copyWith(fontSize: 52),
                  );
                },
              ),
              const SizedBox(width: 5),
              Text(
                '%',
                style: PaceUpTypography.heading(accent).copyWith(fontSize: 20),
              ),
              const Spacer(),
              Text(
                _formatValue(progress.type, progress.currentValue),
                style: PaceUpTypography.bodyMedium(PaceUpColors.darkText),
              ),
              Text(
                ' / ${_formatValue(progress.type, progress.targetValue)}',
                style: PaceUpTypography.body(PaceUpColors.darkMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentage),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: PaceUpColors.darkBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          if (completed)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 17,
                  color: PaceUpColors.electricGreen,
                ),
                const SizedBox(width: 7),
                Text(
                  'CHALLENGE COMPLETED',
                  style: PaceUpTypography.label(PaceUpColors.electricGreen),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${progress.progressPercentage.toStringAsFixed(1)}% COMPLETE',
                    style: PaceUpTypography.label(PaceUpColors.darkMuted),
                  ),
                ),
                Text(
                  '${_formatValue(progress.type, progress.remainingValue)} '
                  'REMAINING',
                  style: PaceUpTypography.label(accent),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAction() {
    final hasJoined = _progress != null;
    final isActive = _isActive();
    final isUpcoming = _isUpcoming();

    if (_isJoining) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: PaceUpColors.darkPanel,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: PaceUpColors.darkBorder),
        ),
        child: const Center(
          child: SizedBox(
            width: 21,
            height: 21,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: PaceUpColors.electricGreen,
            ),
          ),
        ),
      );
    }

    if (!isActive && !isUpcoming) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.flag_outlined),
          label: Text(
            'CHALLENGE ENDED',
            style: PaceUpTypography.label(PaceUpColors.darkMuted),
          ),
        ),
      );
    }

    if (hasJoined) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton.icon(
          onPressed: _leave,
          style: OutlinedButton.styleFrom(
            foregroundColor: PaceUpColors.darkText,
            side: const BorderSide(color: PaceUpColors.darkBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: Text(
            'LEAVE CHALLENGE',
            style: PaceUpTypography.label(PaceUpColors.darkText),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: _join,
        style: FilledButton.styleFrom(
          backgroundColor: PaceUpColors.electricGreen,
          foregroundColor: PaceUpColors.greenInk,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(Icons.flash_on_rounded),
        label: Text(
          isUpcoming ? 'JOIN CHALLENGE' : 'JOIN CHALLENGE',
          style: PaceUpTypography.label(PaceUpColors.greenInk),
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    final leaderboard = _leaderboard!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COMPETE',
                    style: PaceUpTypography.sectionTitle(
                      PaceUpColors.electricGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CHALLENGE LEADERBOARD',
                    style: PaceUpTypography.heading(PaceUpColors.darkText),
                  ),
                ],
              ),
            ),
            if (leaderboard.participants.isNotEmpty)
              Text(
                '${leaderboard.participants.length} ATHLETES',
                style: PaceUpTypography.label(PaceUpColors.darkMuted),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (leaderboard.participants.isEmpty)
          _buildEmptyLeaderboard()
        else
          Container(
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: PaceUpColors.darkBorder),
            ),
            child: Column(
              children: leaderboard.participants
                  .asMap()
                  .entries
                  .map(
                    (entry) => _LeaderboardRow(
                      participant: entry.value,
                      challengeType: widget.challenge.type,
                      isLast: entry.key == leaderboard.participants.length - 1,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyLeaderboard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PaceUpColors.darkBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: PaceUpColors.electricCyan.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_2_outlined,
              color: PaceUpColors.electricCyan,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'NO PARTICIPANTS YET',
            style: PaceUpTypography.bodyMedium(PaceUpColors.darkText),
          ),
          const SizedBox(height: 5),
          Text(
            'Be the first athlete to join this challenge.',
            textAlign: TextAlign.center,
            style: PaceUpTypography.body(PaceUpColors.darkMuted),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: PaceUpTypography.label(PaceUpColors.darkMuted)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PaceUpTypography.bodyMedium(accent).copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final dynamic participant;
  final String challengeType;
  final bool isLast;

  const _LeaderboardRow({
    required this.participant,
    required this.challengeType,
    required this.isLast,
  });

  String _formatValue(double value) {
    switch (challengeType) {
      case 'Distance':
        return '${value.toStringAsFixed(1)} km';
      case 'Duration':
        final minutes = (value / 60).floor();
        final seconds = value.round() % 60;
        return '${minutes}m ${seconds}s';
      case 'Activities':
        return value.toStringAsFixed(0);
      default:
        return value.toStringAsFixed(1);
    }
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Color _rankColor(int rank) {
    if (rank == 1) {
      return PaceUpColors.electricGreen;
    }

    if (rank == 2) {
      return const Color(0xFFC7D0D8);
    }

    if (rank == 3) {
      return const Color(0xFFD49A68);
    }

    return PaceUpColors.darkMuted;
  }

  @override
  Widget build(BuildContext context) {
    final rank = participant.rank as int;
    final accent = _rankColor(rank);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (rank * 55)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(18 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: PaceUpColors.darkBorder),
                ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text('#$rank', style: PaceUpTypography.bodyMedium(accent)),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Center(
                child: Text(
                  _initials(participant.displayName as String),
                  style: PaceUpTypography.label(accent),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant.displayName as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PaceUpTypography.bodyMedium(PaceUpColors.darkText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${participant.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PaceUpTypography.body(PaceUpColors.darkMuted)
                        .copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatValue(participant.currentValue as double),
              style: PaceUpTypography.bodyMedium(accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  final double height;
  final double radius;

  const _LoadingBlock({required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: PaceUpColors.darkBorder),
      ),
    );
  }
}
