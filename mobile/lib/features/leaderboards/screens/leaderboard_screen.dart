import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/leaderboard_models.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardService _leaderboardService = LeaderboardService();

  List<LeaderboardEntryResponse> _entries = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _period = 'weekly';

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final entries = await _leaderboardService.getLeaderboard(
        period: _period,
        limit: 10,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _entries = entries;
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

  void _changePeriod(String period) {
    if (_period == period) {
      return;
    }

    setState(() {
      _period = period;
    });

    _loadLeaderboard();
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
              'COMPETE',
              style: PaceUpTypography.label(
                PaceUpColors.electricGreen,
              ).copyWith(
                fontSize: 9,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'LEADERBOARD',
              style: PaceUpTypography.heading(
                PaceUpColors.darkText,
              ).copyWith(
                fontSize: 23,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: PaceUpColors.electricGreen,
        backgroundColor: PaceUpColors.darkPanel,
        onRefresh: _loadLeaderboard,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const _LeaderboardLoadingHero(),
          const SizedBox(height: 18),
          ...List.generate(
            6,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 9),
              child: _LeaderboardSkeleton(),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null && _entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanel,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: PaceUpColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.leaderboard_outlined,
                  size: 46,
                  color: PaceUpColors.danger,
                ),
                const SizedBox(height: 16),
                Text(
                  'LEADERBOARD UNAVAILABLE',
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
                  onPressed: _loadLeaderboard,
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

    if (_entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const _LeaderboardHero(
            entries: [],
          ),
          const SizedBox(height: 18),
          const _EmptyLeaderboard(),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        _LeaderboardHero(
          entries: _entries,
        ),
        const SizedBox(height: 18),
        _PeriodSelector(
          selectedPeriod: _period,
          onChanged: _changePeriod,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Text(
              'TOP ATHLETES',
              style: PaceUpTypography.sectionTitle(
                PaceUpColors.darkMuted,
              ),
            ),
            const Spacer(),
            if (_isLoading)
              const SizedBox(
                height: 13,
                width: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: PaceUpColors.electricGreen,
                ),
              )
            else
              Text(
                '${_entries.length} ATHLETES',
                style: PaceUpTypography.label(
                  PaceUpColors.darkMuted,
                ).copyWith(fontSize: 8),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ..._entries.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _LeaderboardRow(
              entry: entry.value,
              index: entry.key,
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardHero extends StatelessWidget {
  final List<LeaderboardEntryResponse> entries;

  const _LeaderboardHero({
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final topEntry = entries.isNotEmpty ? entries.first : null;

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
            color: PaceUpColors.electricGreen.withValues(alpha: 0.045),
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
                  color: PaceUpColors.electricGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: PaceUpColors.greenInk,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DISTANCE RANKING',
                      style: PaceUpTypography.label(
                        PaceUpColors.electricGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Push your limits.',
                      style: PaceUpTypography.heading(
                        PaceUpColors.darkText,
                      ).copyWith(fontSize: 23),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (topEntry != null) ...[
            Text(
              'CURRENT #1',
              style: PaceUpTypography.label(
                PaceUpColors.darkMuted,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    topEntry.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PaceUpTypography.heading(
                      PaceUpColors.darkText,
                    ).copyWith(
                      fontSize: 27,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  topEntry.distanceKm.toStringAsFixed(1),
                  style: PaceUpTypography.largeMetric(
                    PaceUpColors.electricGreen,
                  ).copyWith(
                    fontSize: 38,
                    height: 0.9,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 5,
                    bottom: 4,
                  ),
                  child: Text(
                    'KM',
                    style: PaceUpTypography.label(
                      PaceUpColors.darkMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '@${topEntry.username}',
              style: PaceUpTypography.body(
                PaceUpColors.darkMuted,
              ),
            ),
          ] else ...[
            Text(
              'CLIMB THE RANKS.',
              style: PaceUpTypography.heading(
                PaceUpColors.darkText,
              ).copyWith(fontSize: 25),
            ),
            const SizedBox(height: 6),
            Text(
              'Complete activities to start competing.',
              style: PaceUpTypography.body(
                PaceUpColors.darkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Row(
        children: [
          _PeriodButton(
            label: 'WEEK',
            selected: selectedPeriod == 'weekly',
            onTap: () => onChanged('weekly'),
          ),
          _PeriodButton(
            label: 'MONTH',
            selected: selectedPeriod == 'monthly',
            onTap: () => onChanged('monthly'),
          ),
          _PeriodButton(
            label: 'ALL TIME',
            selected: selectedPeriod == 'all-time',
            onTap: () => onChanged('all-time'),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? PaceUpColors.electricGreen.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: selected
                ? Border.all(
                    color: PaceUpColors.electricGreen.withValues(
                      alpha: 0.22,
                    ),
                  )
                : null,
          ),
          child: Text(
            label,
            style: PaceUpTypography.label(
              selected
                  ? PaceUpColors.electricGreen
                  : PaceUpColors.darkMuted,
            ).copyWith(
              fontSize: 8,
              letterSpacing: 0.9,
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntryResponse entry;
  final int index;

  const _LeaderboardRow({
    required this.entry,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isTopThree = entry.rank <= 3;
    final isCurrentUser = entry.isCurrentUser;

    final rankAccent = switch (entry.rank) {
      1 => PaceUpColors.electricGreen,
      2 => const Color(0xFFD5DEE5),
      3 => const Color(0xFFD49A63),
      _ => PaceUpColors.darkMuted,
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: 280 + (index * 50).clamp(0, 300),
      ),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? PaceUpColors.darkPanelSecondary
              : PaceUpColors.darkPanel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentUser
                ? PaceUpColors.electricGreen.withValues(alpha: 0.55)
                : isTopThree
                    ? rankAccent.withValues(alpha: 0.22)
                    : PaceUpColors.darkBorder,
          ),
          boxShadow: isCurrentUser
              ? [
                  BoxShadow(
                    color: PaceUpColors.electricGreen.withValues(
                      alpha: 0.045,
                    ),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#${entry.rank}',
                style: PaceUpTypography.bodyMedium(
                  rankAccent,
                ).copyWith(
                  fontSize: isTopThree ? 15 : 12,
                ),
              ),
            ),
            _Avatar(
              imageUrl: entry.profileImageUrl,
              rank: entry.rank,
              accent: rankAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PaceUpTypography.bodyMedium(
                            PaceUpColors.darkText,
                          ).copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: PaceUpColors.electricGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'YOU',
                            style: PaceUpTypography.label(
                              PaceUpColors.greenInk,
                            ).copyWith(
                              fontSize: 7,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${entry.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PaceUpTypography.body(
                      PaceUpColors.darkMuted,
                    ).copyWith(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.distanceKm.toStringAsFixed(1),
                  style: PaceUpTypography.largeMetric(
                    isTopThree
                        ? rankAccent
                        : PaceUpColors.darkText,
                  ).copyWith(
                    fontSize: 26,
                    height: 0.9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'KM',
                  style: PaceUpTypography.label(
                    PaceUpColors.darkMuted,
                  ).copyWith(
                    fontSize: 7,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final int rank;
  final Color accent;

  const _Avatar({
    required this.imageUrl,
    required this.rank,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanelSecondary,
        shape: BoxShape.circle,
        border: Border.all(
          color: rank <= 3
              ? accent.withValues(alpha: 0.65)
              : PaceUpColors.darkBorder,
          width: rank <= 3 ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                return Icon(
                  Icons.person_outline_rounded,
                  color: PaceUpColors.darkMuted,
                  size: 21,
                );
              },
            )
          : const Icon(
              Icons.person_outline_rounded,
              color: PaceUpColors.darkMuted,
              size: 21,
            ),
    );
  }
}

class _EmptyLeaderboard extends StatelessWidget {
  const _EmptyLeaderboard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: PaceUpColors.electricGreen.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.leaderboard_outlined,
              size: 30,
              color: PaceUpColors.electricGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'NO RANKINGS YET',
            style: PaceUpTypography.heading(
              PaceUpColors.darkText,
            ).copyWith(fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete activities to start climbing the leaderboard.',
            textAlign: TextAlign.center,
            style: PaceUpTypography.body(
              PaceUpColors.darkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardLoadingHero extends StatelessWidget {
  const _LeaderboardLoadingHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 185,
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

class _LeaderboardSkeleton extends StatelessWidget {
  const _LeaderboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 12,
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanelSecondary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 43,
            height: 43,
            decoration: const BoxDecoration(
              color: PaceUpColors.darkPanelSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 10,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  width: 75,
                  height: 8,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 45,
            height: 25,
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanelSecondary,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}