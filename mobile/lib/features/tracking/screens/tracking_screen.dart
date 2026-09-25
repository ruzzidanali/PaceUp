import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../achievements/models/achievement_models.dart';
import '../../achievements/services/achievement_service.dart';
import '../../activities/models/activity_models.dart';
import '../../activities/services/activity_service.dart';
import '../controllers/tracking_controller.dart';
import '../models/route_models.dart';
import '../services/route_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late final TrackingController _controller;
  late final ActivityService _activityService;
  late final AchievementService _achievementService;
  late final RouteService _routeService;

  Timer? _timer;
  bool _isSaving = false;

  String _selectedType = 'Run';

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

    _controller = TrackingController();
    _activityService = ActivityService();
    _achievementService = AchievementService();
    _routeService = RouteService();

    _controller.addListener(_onTrackingChanged);

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _controller.isTracking) {
        setState(() {});
      }
    });
  }

  void _onTrackingChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_onTrackingChanged);
    _controller.dispose();
    _activityService.dispose();
    _routeService.dispose();

    super.dispose();
  }

  Future<void> _startTracking() async {
    final started = await _controller.start();

    if (!mounted) {
      return;
    }

    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.location_off_outlined,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Location permission is required to start tracking.',
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showAchievementUnlockedDialog(
    List<AchievementResponse> achievements,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: PaceUpColors.darkPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: PaceUpColors.electricGreen.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color:
                        PaceUpColors.electricGreen.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          PaceUpColors.electricGreen.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: PaceUpColors.electricGreen,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'ACHIEVEMENT UNLOCKED',
                  textAlign: TextAlign.center,
                  style: PaceUpTypography.sectionTitle(
                    PaceUpColors.electricGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You just earned a new badge.',
                  textAlign: TextAlign.center,
                  style: PaceUpTypography.body(
                    PaceUpColors.darkMuted,
                  ),
                ),
                const SizedBox(height: 22),
                ...achievements.map(
                  (achievement) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: PaceUpColors.darkPanelSecondary,
                        borderRadius: BorderRadius.circular(14),
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
                              color: PaceUpColors.electricGreen
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getAchievementIcon(achievement.icon),
                              color: PaceUpColors.electricGreen,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  achievement.name,
                                  style: PaceUpTypography.bodyMedium(
                                    PaceUpColors.darkText,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  achievement.description,
                                  style: PaceUpTypography.body(
                                    PaceUpColors.darkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: PaceUpColors.electricGreen,
                      foregroundColor: PaceUpColors.greenInk,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'KEEP MOVING',
                      style: PaceUpTypography.label(
                        PaceUpColors.greenInk,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getAchievementIcon(String icon) {
    switch (icon) {
      case 'directions_run':
        return Icons.directions_run_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      case 'straighten':
        return Icons.straighten_rounded;
      case 'timer':
        return Icons.timer_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'Run':
        return Icons.directions_run_rounded;
      case 'Ride':
        return Icons.directions_bike_rounded;
      case 'Walk':
        return Icons.directions_walk_rounded;
      case 'Hike':
        return Icons.terrain_rounded;
      case 'Swim':
        return Icons.pool_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  String _activityLabel(String type) {
    switch (type) {
      case 'Run':
        return 'RUN';
      case 'Ride':
        return 'RIDE';
      case 'Walk':
        return 'WALK';
      case 'Hike':
        return 'HIKE';
      case 'Swim':
        return 'SWIM';
      default:
        return 'OTHER';
    }
  }

  Future<void> _stopTracking() async {
    if (_isSaving) {
      return;
    }

    await _controller.stop();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final startedAt = _controller.startedAt;

    if (startedAt == null) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final distanceKm = _controller.distanceMeters / 1000;
    final durationSeconds = _controller.durationSeconds;
    final trackingPoints = _controller.points;

    setState(() {});

    try {
      final achievementsBefore =
          await _achievementService.getAchievements();

      final activity = await _activityService.createActivity(
        CreateActivityRequest(
          type: _selectedType,
          distance: distanceKm,
          durationSeconds: durationSeconds,
          calories: null,
          startedAt: startedAt,
        ),
      );

      final routeRequest = CreateActivityRouteRequest(
        points: trackingPoints
            .map(
              (point) => CreateActivityPointRequest(
                latitude: point.latitude,
                longitude: point.longitude,
                altitude: point.altitude,
                accuracy: point.accuracy,
                speed: point.speed,
                heartRate: point.heartRate,
                recordedAt: point.recordedAt,
              ),
            )
            .toList(),
      );

      await _routeService.createRoute(
        activity.id,
        routeRequest,
      );

      final achievementsAfter =
          await _achievementService.getAchievements();

      final newlyUnlocked = _achievementService.findNewlyUnlocked(
        achievementsBefore,
        achievementsAfter,
      );

      if (newlyUnlocked.isNotEmpty) {
        await _showAchievementUnlockedDialog(newlyUnlocked);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_activityLabel(_selectedType)} saved. '
            '${distanceKm.toStringAsFixed(2)} km recorded.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _togglePause() {
    if (_controller.isPaused) {
      _controller.resume();
    } else {
      _controller.pause();
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${remainingSeconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatPace(double secondsPerKm) {
    if (secondsPerKm <= 0 || !secondsPerKm.isFinite) {
      return '--:--';
    }

    final totalSeconds = secondsPerKm.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildActivitySelector() {
    final trackingStarted = _controller.isTracking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ACTIVITY',
              style: PaceUpTypography.sectionTitle(
                PaceUpColors.darkMuted,
              ),
            ),
            const Spacer(),
            if (trackingStarted)
              Text(
                'LOCKED',
                style: PaceUpTypography.label(
                  PaceUpColors.darkMuted,
                ).copyWith(
                  fontSize: 8,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: trackingStarted
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            itemCount: _activityTypes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final type = _activityTypes[index];
              final selected = _selectedType == type;

              return GestureDetector(
                onTap: trackingStarted || _isSaving
                    ? null
                    : () {
                        setState(() {
                          _selectedType = type;
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 78,
                  decoration: BoxDecoration(
                    color: selected
                        ? PaceUpColors.electricGreen
                        : PaceUpColors.darkPanel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? PaceUpColors.electricGreen
                          : PaceUpColors.darkBorder,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _activityIcon(type),
                        size: 22,
                        color: selected
                            ? PaceUpColors.greenInk
                            : PaceUpColors.darkMuted,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _activityLabel(type),
                        style: PaceUpTypography.label(
                          selected
                              ? PaceUpColors.greenInk
                              : PaceUpColors.darkMuted,
                        ).copyWith(
                          fontSize: 8,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required String unit,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: PaceUpTypography.label(
              PaceUpColors.darkMuted,
            ).copyWith(
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: PaceUpTypography.largeMetric(
              valueColor ?? PaceUpColors.darkText,
            ).copyWith(
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: PaceUpTypography.label(
              PaceUpColors.darkMuted,
            ).copyWith(
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsStatus() {
    final tracking = _controller.isTracking;
    final paused = _controller.isPaused;

    final Color statusColor;

    if (paused) {
      statusColor = PaceUpColors.electricCyan;
    } else if (tracking) {
      statusColor = PaceUpColors.electricGreen;
    } else {
      statusColor = PaceUpColors.darkMuted;
    }

    final String statusText;

    if (paused) {
      statusText = 'TRACKING PAUSED';
    } else if (tracking) {
      statusText = 'GPS TRACKING ACTIVE';
    } else {
      statusText = 'READY TO TRACK';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: tracking && !paused
                  ? [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.65),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: PaceUpTypography.label(
              statusColor,
            ).copyWith(
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = _controller.distanceMeters / 1000;
    final tracking = _controller.isTracking;

    return Scaffold(
      backgroundColor: PaceUpColors.darkBackground,
      appBar: AppBar(
        backgroundColor: PaceUpColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TRACKING',
              style: PaceUpTypography.sectionTitle(
                PaceUpColors.darkMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _activityLabel(_selectedType),
              style: PaceUpTypography.heading(
                PaceUpColors.darkText,
              ).copyWith(
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGpsStatus(),
              const SizedBox(height: 20),
              _buildActivitySelector(),
              const SizedBox(height: 28),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Column(
                    key: ValueKey(
                      '${_selectedType}_${tracking}_${_controller.isPaused}',
                    ),
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: PaceUpColors.electricGreen
                              .withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: PaceUpColors.electricGreen
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          _activityIcon(_selectedType),
                          color: PaceUpColors.electricGreen,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        distanceKm.toStringAsFixed(2),
                        style: PaceUpTypography.heroMetric(
                          PaceUpColors.darkText,
                        ),
                      ),
                      Text(
                        'KM',
                        style: PaceUpTypography.sectionTitle(
                          PaceUpColors.electricGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _buildMetric(
                label: 'DURATION',
                value: _formatDuration(
                  _controller.durationSeconds,
                ),
                unit: 'TIME',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetric(
                      label: 'CURRENT PACE',
                      value: _formatPace(
                        _controller.currentPaceSecondsPerKm,
                      ),
                      unit: 'MIN / KM',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetric(
                      label: 'AVG PACE',
                      value: _formatPace(
                        _controller.averagePaceSecondsPerKm,
                      ),
                      unit: 'MIN / KM',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildMetric(
                label: 'GPS DATA',
                value: '${_controller.points.length}',
                unit: 'POINTS RECORDED',
                valueColor: PaceUpColors.electricCyan,
              ),
              const SizedBox(height: 28),
              if (!tracking)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _startTracking,
                    style: FilledButton.styleFrom(
                      backgroundColor: PaceUpColors.electricGreen,
                      foregroundColor: PaceUpColors.greenInk,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      size: 24,
                    ),
                    label: Text(
                      'START TRACKING',
                      style: PaceUpTypography.label(
                        PaceUpColors.greenInk,
                      ).copyWith(
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed:
                              _isSaving ? null : _togglePause,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PaceUpColors.darkText,
                            side: const BorderSide(
                              color: PaceUpColors.darkBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          icon: Icon(
                            _controller.isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                          ),
                          label: Text(
                            _controller.isPaused
                                ? 'RESUME'
                                : 'PAUSE',
                            style: PaceUpTypography.label(
                              PaceUpColors.darkText,
                            ).copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _isSaving
                              ? null
                              : _stopTracking,
                          style: FilledButton.styleFrom(
                            backgroundColor: PaceUpColors.electricGreen,
                            foregroundColor: PaceUpColors.greenInk,
                            disabledBackgroundColor:
                                PaceUpColors.darkPanelSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        PaceUpColors.darkMuted,
                                  ),
                                )
                              : const Icon(
                                  Icons.stop_rounded,
                                ),
                          label: Text(
                            _isSaving ? 'SAVING' : 'STOP & SAVE',
                            style: PaceUpTypography.label(
                              PaceUpColors.greenInk,
                            ).copyWith(
                              fontSize: 10,
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
      ),
    );
  }
}