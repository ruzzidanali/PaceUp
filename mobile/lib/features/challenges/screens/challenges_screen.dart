import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/challenge_models.dart';
import '../services/challenge_service.dart';
import 'add_challenge_screen.dart';
import 'challenge_details_screen.dart';
import '../../auth/services/auth_state.dart';

class ChallengesScreen extends StatefulWidget {
  final AuthController authController;

  const ChallengesScreen({super.key, required this.authController});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  late final ChallengeService _challengeService;

  bool _isLoading = true;
  String? _errorMessage;
  List<ChallengeResponse> _challenges = [];

  @override
  void initState() {
    super.initState();
    _challengeService = ChallengeService();
    _loadChallenges();
  }

  @override
  void dispose() {
    _challengeService.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final challenges = await _challengeService.getChallenges();

      if (!mounted) {
        return;
      }

      setState(() {
        _challenges = challenges;
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

  Future<void> _openCreateChallenge() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddChallengeScreen(challengeService: _challengeService),
      ),
    );

    if (created == true && mounted) {
      await _loadChallenges();
    }
  }

  Future<void> _openChallenge(ChallengeResponse challenge) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChallengeDetailsScreen(
          challenge: challenge,
          challengeService: _challengeService,
          authController: widget.authController,
        ),
      ),
    );

    if (mounted) {
      await _loadChallenges();
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _formatTarget(ChallengeResponse challenge) {
    switch (challenge.type) {
      case 'Distance':
        return '${challenge.targetValue.toStringAsFixed(1)} km';
      case 'Duration':
        final minutes = (challenge.targetValue / 60).round();
        return '$minutes min';
      case 'Activities':
        return '${challenge.targetValue.toStringAsFixed(0)} activities';
      default:
        return challenge.targetValue.toString();
    }
  }

  String _targetLabel(ChallengeResponse challenge) {
    switch (challenge.type) {
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

  bool _isActive(ChallengeResponse challenge) {
    final now = DateTime.now();

    return !now.isBefore(challenge.startDate) &&
        !now.isAfter(challenge.endDate);
  }

  bool _isUpcoming(ChallengeResponse challenge) {
    return DateTime.now().isBefore(challenge.startDate);
  }

  int get _activeCount {
    return _challenges.where(_isActive).length;
  }

  int get _upcomingCount {
    return _challenges.where(_isUpcoming).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaceUpColors.darkBackground,
      body: RefreshIndicator(
        onRefresh: _loadChallenges,
        color: PaceUpColors.electricGreen,
        backgroundColor: PaceUpColors.darkPanel,
        child: _buildBody(),
      ),
      floatingActionButton: _buildCreateButton(),
    );
  }

  Widget _buildCreateButton() {
    return FloatingActionButton.extended(
      onPressed: _openCreateChallenge,
      backgroundColor: PaceUpColors.electricGreen,
      foregroundColor: PaceUpColors.greenInk,
      elevation: 5,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'CREATE',
        style: PaceUpTypography.label(PaceUpColors.greenInk),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        children: const [
          _ChallengeLoadingHero(),
          SizedBox(height: 22),
          _ChallengeSkeleton(),
          SizedBox(height: 12),
          _ChallengeSkeleton(),
          SizedBox(height: 12),
          _ChallengeSkeleton(),
        ],
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_challenges.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        _buildHeader(),
        const SizedBox(height: 22),
        _buildSummaryHero(),
        const SizedBox(height: 26),
        Text(
          'YOUR CHALLENGES',
          style: PaceUpTypography.sectionTitle(PaceUpColors.darkMuted),
        ),
        const SizedBox(height: 12),
        ..._challenges.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChallengeCard(
              challenge: entry.value,
              isActive: _isActive(entry.value),
              isUpcoming: _isUpcoming(entry.value),
              onTap: () => _openChallenge(entry.value),
              icon: _challengeIcon(entry.value.type),
              targetLabel: _targetLabel(entry.value),
              targetText: _formatTarget(entry.value),
              startDate: _formatDate(entry.value.startDate),
              endDate: _formatDate(entry.value.endDate),
              index: entry.key,
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
        const SizedBox(height: 6),
        Text(
          'CHALLENGES',
          style: PaceUpTypography.heading(PaceUpColors.darkText)
              .copyWith(fontSize: 34, letterSpacing: 0.2),
        ),
        const SizedBox(height: 7),
        Text(
          'Push your limits. Chase the next milestone.',
          style: PaceUpTypography.body(PaceUpColors.darkMuted),
        ),
      ],
    );
  }

  Widget _buildSummaryHero() {
    final total = _challenges.length;
    final active = _activeCount;
    final upcoming = _upcomingCount;

    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PaceUpColors.electricGreen.withValues(alpha: 0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: PaceUpColors.electricGreen.withValues(alpha: 0.045),
            blurRadius: 28,
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: PaceUpColors.electricGreen,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: PaceUpColors.greenInk,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHALLENGE HUB',
                      style: PaceUpTypography.label(PaceUpColors.electricGreen),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'READY TO COMPETE?',
                      style: PaceUpTypography.heading(PaceUpColors.darkText)
                          .copyWith(fontSize: 22),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 23),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  value: total.toString(),
                  label: 'TOTAL',
                  accent: PaceUpColors.darkText,
                ),
              ),
              const _SummaryDivider(),
              Expanded(
                child: _SummaryMetric(
                  value: active.toString(),
                  label: 'ACTIVE',
                  accent: PaceUpColors.electricGreen,
                ),
              ),
              const _SummaryDivider(),
              Expanded(
                child: _SummaryMetric(
                  value: upcoming.toString(),
                  label: 'UPCOMING',
                  accent: PaceUpColors.electricCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Every challenge is another chance to outperform your previous best.',
            style: PaceUpTypography.body(PaceUpColors.darkMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: PaceUpColors.darkPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: PaceUpColors.danger.withValues(alpha: 0.28),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: PaceUpColors.danger.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  color: PaceUpColors.danger,
                  size: 31,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'CHALLENGES UNAVAILABLE',
                textAlign: TextAlign.center,
                style: PaceUpTypography.heading(PaceUpColors.darkText)
                    .copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: PaceUpTypography.body(PaceUpColors.darkMuted),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _loadChallenges,
                style: OutlinedButton.styleFrom(
                  foregroundColor: PaceUpColors.electricGreen,
                  side: BorderSide(
                    color: PaceUpColors.electricGreen.withValues(alpha: 0.4),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  'TRY AGAIN',
                  style: PaceUpTypography.label(PaceUpColors.electricGreen),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 90, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: PaceUpColors.darkPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PaceUpColors.darkBorder),
          ),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: PaceUpColors.electricGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: PaceUpColors.electricGreen,
                  size: 34,
                ),
              ),
              const SizedBox(height: 19),
              Text(
                'NO CHALLENGES YET',
                textAlign: TextAlign.center,
                style: PaceUpTypography.heading(PaceUpColors.darkText)
                    .copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a challenge and start competing with your friends.',
                textAlign: TextAlign.center,
                style: PaceUpTypography.body(PaceUpColors.darkMuted),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _openCreateChallenge,
                style: FilledButton.styleFrom(
                  backgroundColor: PaceUpColors.electricGreen,
                  foregroundColor: PaceUpColors.greenInk,
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'CREATE CHALLENGE',
                  style: PaceUpTypography.label(PaceUpColors.greenInk),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;

  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: PaceUpTypography.largeMetric(accent).copyWith(fontSize: 30),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: PaceUpTypography.label(PaceUpColors.darkMuted)
              .copyWith(fontSize: 8),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: PaceUpColors.darkBorder,
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeResponse challenge;
  final bool isActive;
  final bool isUpcoming;
  final VoidCallback onTap;
  final IconData icon;
  final String targetLabel;
  final String targetText;
  final String startDate;
  final String endDate;
  final int index;

  const _ChallengeCard({
    required this.challenge,
    required this.isActive,
    required this.isUpcoming,
    required this.onTap,
    required this.icon,
    required this.targetLabel,
    required this.targetText,
    required this.startDate,
    required this.endDate,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isActive
        ? PaceUpColors.electricGreen
        : isUpcoming
        ? PaceUpColors.electricCyan
        : PaceUpColors.darkMuted;

    final statusText = isActive
        ? 'ACTIVE'
        : isUpcoming
        ? 'UPCOMING'
        : 'ENDED';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index * 65).clamp(0, 400)),
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
      child: Material(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? PaceUpColors.electricGreen.withValues(alpha: 0.38)
                    : PaceUpColors.darkBorder,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: PaceUpColors.electricGreen.withValues(
                          alpha: 0.045,
                        ),
                        blurRadius: 20,
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
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Icon(icon, color: accent, size: 24),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  challenge.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: PaceUpTypography.bodyMedium(
                                    PaceUpColors.darkText,
                                  ).copyWith(fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 13,
                                color: PaceUpColors.darkMuted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusText,
                              style: PaceUpTypography.label(accent)
                                  .copyWith(fontSize: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (challenge.description != null &&
                    challenge.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 15),
                  Text(
                    challenge.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: PaceUpTypography.body(PaceUpColors.darkMuted),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ChallengeMetric(
                        label: targetLabel,
                        value: targetText,
                        accent: accent,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 38,
                      color: PaceUpColors.darkBorder,
                    ),
                    Expanded(
                      child: _ChallengeMetric(
                        label: 'PARTICIPANTS',
                        value: challenge.participantCount.toString(),
                        accent: PaceUpColors.electricCyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Container(height: 1, color: PaceUpColors.darkBorder),
                const SizedBox(height: 11),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: PaceUpColors.darkMuted,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '$startDate → $endDate',
                        style: PaceUpTypography.body(PaceUpColors.darkMuted)
                            .copyWith(fontSize: 10.5),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 19,
                      color: PaceUpColors.darkMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengeMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _ChallengeMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: PaceUpTypography.label(PaceUpColors.darkMuted)
                .copyWith(fontSize: 7.5),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PaceUpTypography.bodyMedium(accent).copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ChallengeLoadingHero extends StatelessWidget {
  const _ChallengeLoadingHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 195,
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PaceUpColors.darkBorder),
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

class _ChallengeSkeleton extends StatelessWidget {
  const _ChallengeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PaceUpColors.darkBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanelSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 15,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  width: 65,
                  height: 17,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 120,
                  height: 11,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: PaceUpColors.darkBorder,
                ),
                const SizedBox(height: 10),
                Container(
                  width: 150,
                  height: 10,
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
