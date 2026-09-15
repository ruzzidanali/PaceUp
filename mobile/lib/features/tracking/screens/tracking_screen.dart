import 'dart:async';

import 'package:flutter/material.dart';

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
  late final RouteService _routeService;

  Timer? _timer;
  bool _isSaving = false;

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

  @override
  void initState() {
    super.initState();

    _controller = TrackingController();
    _activityService = ActivityService();
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
          content: Text('Location permission is required to start tracking.'),
        ),
      );
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
      final activity = await _activityService.createActivity(
        CreateActivityRequest(
          type: 'Run',
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

      await _routeService.createRoute(activity.id, routeRequest);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Activity saved. '
            '${distanceKm.toStringAsFixed(2)} km recorded.',
          ),
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
          content: Text(e.toString().replaceFirst('Exception: ', '')),
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

  @override
  Widget build(BuildContext context) {
    final distanceKm = _controller.distanceMeters / 1000;

    return Scaffold(
      appBar: AppBar(title: const Text('Track Activity')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_run_rounded, size: 64),
                      const SizedBox(height: 24),
                      Text(
                        distanceKm.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text('km', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 40),
                      Text(
                        _formatDuration(_controller.durationSeconds),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text('Duration'),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                _formatPace(
                                  _controller.currentPaceSecondsPerKm,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const Text('Current Pace'),
                            ],
                          ),
                          const SizedBox(width: 40),
                          Column(
                            children: [
                              Text(
                                _formatPace(
                                  _controller.averagePaceSecondsPerKm,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const Text('Avg Pace'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '${_controller.points.length}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Text('GPS points'),
                    ],
                  ),
                ),
              ),
              if (!_controller.isTracking)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _startTracking,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _togglePause,
                        icon: Icon(
                          _controller.isPaused ? Icons.play_arrow : Icons.pause,
                        ),
                        label: Text(_controller.isPaused ? 'Resume' : 'Pause'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _stopTracking,
                        icon: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.stop),
                        label: Text(_isSaving ? 'Saving...' : 'Stop'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
