import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/personal_record_models.dart';
import '../services/personal_record_service.dart';

class PersonalRecordsScreen extends StatefulWidget {
  const PersonalRecordsScreen({super.key});

  @override
  State<PersonalRecordsScreen> createState() => _PersonalRecordsScreenState();
}

class _PersonalRecordsScreenState extends State<PersonalRecordsScreen> {
  final PersonalRecordService _service = PersonalRecordService();

  PersonalRecordResponse? _records;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final records = await _service.getPersonalRecords();

      if (!mounted) {
        return;
      }

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) {
      return '--';
    }

    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    }

    return '${remainingSeconds}s';
  }

  String _formatPace(double? secondsPerKm) {
    if (secondsPerKm == null) {
      return '--';
    }

    final totalSeconds = secondsPerKm.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
  }

  String _formatNumber(double? value) {
    if (value == null) {
      return '--';
    }

    return value.toStringAsFixed(1);
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
              'PERFORMANCE',
              style: PaceUpTypography.label(
                PaceUpColors.electricGreen,
              ).copyWith(
                fontSize: 9,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'PERSONAL RECORDS',
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
        onRefresh: _loadRecords,
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
          const _RecordsLoadingHero(),
          const SizedBox(height: 18),
          ...List.generate(
            5,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: _RecordSkeleton(),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
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
                  Icons.error_outline_rounded,
                  size: 46,
                  color: PaceUpColors.danger,
                ),
                const SizedBox(height: 16),
                Text(
                  'RECORDS UNAVAILABLE',
                  textAlign: TextAlign.center,
                  style: PaceUpTypography.heading(
                    PaceUpColors.darkText,
                  ).copyWith(fontSize: 21),
                ),
                const SizedBox(height: 8),
                Text(
                  'Something went wrong while loading your personal records.',
                  textAlign: TextAlign.center,
                  style: PaceUpTypography.body(
                    PaceUpColors.darkMuted,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _loadRecords,
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

    final records = _records;

    if (records == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanel,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: PaceUpColors.darkBorder,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: PaceUpColors.electricGreen.withValues(
                      alpha: 0.08,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    size: 31,
                    color: PaceUpColors.electricGreen,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'NO RECORDS YET',
                  textAlign: TextAlign.center,
                  style: PaceUpTypography.heading(
                    PaceUpColors.darkText,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Complete activities to start building your personal records.',
                  textAlign: TextAlign.center,
                  style: PaceUpTypography.body(
                    PaceUpColors.darkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        _RecordsHero(records: records),
        const SizedBox(height: 26),
        Text(
          'YOUR BEST',
          style: PaceUpTypography.sectionTitle(
            PaceUpColors.darkMuted,
          ),
        ),
        const SizedBox(height: 12),
        _RecordCard(
          icon: Icons.straighten_rounded,
          label: 'LONGEST DISTANCE',
          value: _formatNumber(records.longestDistanceKm),
          unit: records.longestDistanceKm == null ? '' : 'KM',
          accent: PaceUpColors.electricGreen,
          index: 0,
        ),
        const SizedBox(height: 10),
        _RecordCard(
          icon: Icons.timer_outlined,
          label: 'LONGEST DURATION',
          value: _formatDuration(records.longestDurationSeconds),
          unit: '',
          accent: PaceUpColors.electricCyan,
          index: 1,
        ),
        const SizedBox(height: 10),
        _RecordCard(
          icon: Icons.speed_rounded,
          label: 'FASTEST SPEED',
          value: _formatNumber(records.fastestSpeedKmh),
          unit: records.fastestSpeedKmh == null ? '' : 'KM/H',
          accent: PaceUpColors.electricGreen,
          index: 2,
        ),
        const SizedBox(height: 10),
        _RecordCard(
          icon: Icons.bolt_rounded,
          label: 'FASTEST PACE',
          value: _formatPace(records.fastestPaceSecondsPerKm),
          unit: '',
          accent: PaceUpColors.electricCyan,
          index: 3,
        ),
        const SizedBox(height: 10),
        _RecordCard(
          icon: Icons.local_fire_department_outlined,
          label: 'MOST CALORIES',
          value: records.mostCalories?.toString() ?? '--',
          unit: records.mostCalories == null ? '' : 'KCAL',
          accent: const Color(0xFFFF9F43),
          index: 4,
        ),
      ],
    );
  }
}

class _RecordsHero extends StatelessWidget {
  final PersonalRecordResponse records;

  const _RecordsHero({
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final recordCount = [
      records.longestDistanceKm,
      records.longestDurationSeconds,
      records.fastestSpeedKmh,
      records.fastestPaceSecondsPerKm,
      records.mostCalories,
    ].where((value) => value != null).length;

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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: PaceUpColors.electricGreen,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
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
                      'ATHLETE PERFORMANCE',
                      style: PaceUpTypography.label(
                        PaceUpColors.electricGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'BEAT YOUR BEST.',
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
          Text(
            '$recordCount / 5 RECORDS SET',
            style: PaceUpTypography.label(
              PaceUpColors.darkMuted,
            ),
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end: recordCount / 5,
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: PaceUpColors.darkBorder,
                  color: PaceUpColors.electricGreen,
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Every session gives you another chance to set a new personal best.',
            style: PaceUpTypography.body(
              PaceUpColors.darkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color accent;
  final int index;

  const _RecordCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.accent,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: 300 + (index * 70).clamp(0, 350),
      ),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) {
        return Opacity(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(
              0,
              10 * (1 - animation),
            ),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(17),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: accent.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(
                icon,
                color: accent,
                size: 23,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: PaceUpTypography.label(
                      PaceUpColors.darkMuted,
                    ).copyWith(
                      fontSize: 8.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          overflow: TextOverflow.ellipsis,
                          style: PaceUpTypography.largeMetric(
                            PaceUpColors.darkText,
                          ).copyWith(
                            fontSize: 30,
                          ),
                        ),
                      ),
                      if (unit.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          unit,
                          style: PaceUpTypography.label(
                            accent,
                          ).copyWith(
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_upward_rounded,
              color: accent.withValues(alpha: 0.45),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordsLoadingHero extends StatelessWidget {
  const _RecordsLoadingHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
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

class _RecordSkeleton extends StatelessWidget {
  const _RecordSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanelSecondary,
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 110,
                  height: 8,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 18,
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