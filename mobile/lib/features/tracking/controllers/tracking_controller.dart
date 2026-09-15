import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/tracking_point.dart';
import '../services/location_service.dart';

class TrackingController extends ChangeNotifier {
  final LocationService _locationService;

  static const double _maxGpsAccuracyMeters = 30;
  static const double _maxSpeedKmh = 40;
  static const double _minimumMovementMeters = 3;

  TrackingController({LocationService? locationService})
    : _locationService = locationService ?? LocationService();

  StreamSubscription<Position>? _positionSubscription;

  final List<TrackingPoint> _points = [];

  DateTime? _startedAt;
  DateTime? _pausedAt;
  Duration _totalPausedDuration = Duration.zero;

  bool _isTracking = false;
  bool _isPaused = false;

  double _distanceMeters = 0;

  List<TrackingPoint> get points => List.unmodifiable(_points);

  DateTime? get startedAt => _startedAt;

  bool get isTracking => _isTracking;

  bool get isPaused => _isPaused;

  double get distanceMeters => _distanceMeters;

  double get averagePaceSecondsPerKm {
    if (_distanceMeters <= 0) {
      return 0;
    }

    final duration = durationSeconds;

    if (duration <= 0) {
      return 0;
    }

    return duration / (_distanceMeters / 1000);
  }

  double get currentPaceSecondsPerKm {
    if (_points.length < 2) {
      return 0;
    }

    final latestPoint = _points.last;

    if (latestPoint.speed == null ||
        latestPoint.speed! <= 0 ||
        !latestPoint.speed!.isFinite) {
      return 0;
    }

    return 1000 / latestPoint.speed!;
  }

  int get durationSeconds {
    if (_startedAt == null) {
      return 0;
    }

    final end = DateTime.now();

    var elapsed = end.difference(_startedAt!) - _totalPausedDuration;

    if (_isPaused && _pausedAt != null) {
      elapsed -= end.difference(_pausedAt!);
    }

    return elapsed.inSeconds.clamp(0, double.maxFinite.toInt());
  }

  Future<bool> start() async {
    if (_isTracking) {
      return true;
    }

    final permissionGranted = await _locationService.ensurePermission();

    if (!permissionGranted) {
      return false;
    }

    _points.clear();
    _distanceMeters = 0;
    _startedAt = DateTime.now();
    _pausedAt = null;
    _totalPausedDuration = Duration.zero;
    _isTracking = true;
    _isPaused = false;

    _positionSubscription = _locationService.getPositionStream().listen(
      _handlePosition,
    );

    notifyListeners();

    return true;
  }

  void pause() {
    if (!_isTracking || _isPaused) {
      return;
    }

    _pausedAt = DateTime.now();
    _isPaused = true;

    notifyListeners();
  }

  void resume() {
    if (!_isTracking || !_isPaused) {
      return;
    }

    if (_pausedAt != null) {
      _totalPausedDuration += DateTime.now().difference(_pausedAt!);
    }

    _pausedAt = null;
    _isPaused = false;

    notifyListeners();
  }

  Future<void> stop() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    if (_isTracking && _isPaused && _pausedAt != null) {
      _totalPausedDuration += DateTime.now().difference(_pausedAt!);
    }

    _pausedAt = null;
    _isTracking = false;
    _isPaused = false;

    notifyListeners();
  }

  void _handlePosition(Position position) {
    if (!_isTracking || _isPaused) {
      return;
    }

    if (!position.latitude.isFinite || !position.longitude.isFinite) {
      return;
    }

    if (!position.accuracy.isFinite ||
        position.accuracy > _maxGpsAccuracyMeters) {
      return;
    }

    final recordedAt = position.timestamp;

    if (_points.isNotEmpty) {
      final previous = _points.last;

      if (!recordedAt.isAfter(previous.recordedAt)) {
        return;
      }

      final segmentDistance = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );

      if (!segmentDistance.isFinite || segmentDistance < 0) {
        return;
      }

      final elapsedSeconds =
          recordedAt.difference(previous.recordedAt).inMilliseconds / 1000;

      if (elapsedSeconds <= 0) {
        return;
      }

      final calculatedSpeedKmh = (segmentDistance / elapsedSeconds) * 3.6;

      if (calculatedSpeedKmh > _maxSpeedKmh) {
        return;
      }

      if (segmentDistance >= _minimumMovementMeters) {
        _distanceMeters += segmentDistance;
      }
    }

    final point = TrackingPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      speed: position.speed >= 0 && position.speed.isFinite
          ? position.speed
          : null,
      recordedAt: recordedAt,
    );

    _points.add(point);

    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
