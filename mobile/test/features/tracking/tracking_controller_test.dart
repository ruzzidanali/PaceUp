import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:mobile/features/tracking/controllers/tracking_controller.dart';
import 'package:mobile/features/tracking/services/location_service.dart';

class FakeLocationService extends LocationService {
  final StreamController<Position> _controller =
      StreamController<Position>.broadcast();

  bool permissionGranted = true;

  @override
  Future<bool> ensurePermission() async {
    return permissionGranted;
  }

  @override
  Stream<Position> getPositionStream() {
    return _controller.stream;
  }

  void emit(Position position) {
    _controller.add(position);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

Position createPosition({
  required double latitude,
  required double longitude,
  DateTime? timestamp,
  double accuracy = 5,
  double speed = 2,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp ?? DateTime.utc(2026, 9, 10, 6),
    accuracy: accuracy,
    altitude: 10,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: speed,
    speedAccuracy: 1,
    floor: null,
    isMocked: true,
  );
}

void main() {
  late FakeLocationService locationService;
  late TrackingController controller;

  setUp(() {
    locationService = FakeLocationService();

    controller = TrackingController(
      locationService: locationService,
    );
  });

  tearDown(() async {
    controller.dispose();
    await locationService.dispose();
  });

  test(
    'start should begin tracking',
    () async {
      final started = await controller.start();

      expect(started, isTrue);
      expect(controller.isTracking, isTrue);
      expect(controller.isPaused, isFalse);
      expect(controller.points, isEmpty);
      expect(controller.distanceMeters, 0);
    },
  );

  test(
    'start should fail when location permission is unavailable',
    () async {
      locationService.permissionGranted = false;

      final started = await controller.start();

      expect(started, isFalse);
      expect(controller.isTracking, isFalse);
      expect(controller.points, isEmpty);
    },
  );

  test(
    'GPS positions should be recorded while tracking',
    () async {
      await controller.start();

      final timestamp =
          DateTime.utc(2026, 9, 10, 6);

      locationService.emit(
        createPosition(
          latitude: 3.1400,
          longitude: 101.6900,
          timestamp: timestamp,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      expect(
        controller.points,
        hasLength(1),
      );

      expect(
        controller.points.first.latitude,
        3.1400,
      );

      expect(
        controller.points.first.longitude,
        101.6900,
      );
    },
  );

  test(
    'distance should increase between GPS points',
    () async {
      await controller.start();

      final firstTimestamp =
          DateTime.utc(2026, 9, 10, 6);

      final secondTimestamp =
          firstTimestamp.add(
        const Duration(seconds: 20),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1400,
          longitude: 101.6900,
          timestamp: firstTimestamp,
        ),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1410,
          longitude: 101.6900,
          timestamp: secondTimestamp,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      expect(
        controller.points,
        hasLength(2),
      );

      expect(
        controller.distanceMeters,
        greaterThan(0),
      );
    },
  );

  test(
    'current pace should be calculated from latest GPS speed',
    () async {
      await controller.start();

      final firstTimestamp =
          DateTime.utc(2026, 9, 10, 6);

      final secondTimestamp =
          firstTimestamp.add(
        const Duration(seconds: 20),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1400,
          longitude: 101.6900,
          timestamp: firstTimestamp,
        ),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1410,
          longitude: 101.6900,
          timestamp: secondTimestamp,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      expect(
        controller.currentPaceSecondsPerKm,
        closeTo(500, 0.001),
      );
    },
  );

  test(
    'average pace should be zero when duration has not elapsed',
    () async {
      await controller.start();

      final firstTimestamp =
          DateTime.utc(2026, 9, 10, 6);

      final secondTimestamp =
          firstTimestamp.add(
        const Duration(seconds: 20),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1400,
          longitude: 101.6900,
          timestamp: firstTimestamp,
        ),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1410,
          longitude: 101.6900,
          timestamp: secondTimestamp,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      expect(
        controller.distanceMeters,
        greaterThan(0),
      );

      expect(
        controller.averagePaceSecondsPerKm,
        0,
      );
    },
  );

  test(
    'average pace should increase after active tracking time',
    () async {
      await controller.start();

      final firstTimestamp =
          DateTime.utc(2026, 9, 10, 6);

      final secondTimestamp =
          firstTimestamp.add(
        const Duration(seconds: 20),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1400,
          longitude: 101.6900,
          timestamp: firstTimestamp,
        ),
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 1100),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1410,
          longitude: 101.6900,
          timestamp: secondTimestamp,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      expect(
        controller.distanceMeters,
        greaterThan(0),
      );

      expect(
        controller.durationSeconds,
        greaterThanOrEqualTo(1),
      );

      expect(
        controller.averagePaceSecondsPerKm,
        greaterThan(0),
      );
    },
  );

  test(
    'pace should be zero when there are not enough GPS points',
    () async {
      await controller.start();

      expect(
        controller.currentPaceSecondsPerKm,
        0,
      );

      expect(
        controller.averagePaceSecondsPerKm,
        0,
      );
    },
  );

  test(
    'pace should remain unchanged while paused',
    () async {
      await controller.start();

      final firstTimestamp =
          DateTime.utc(2026, 9, 10, 6);

      final secondTimestamp =
          firstTimestamp.add(
        const Duration(seconds: 20),
      );

      final thirdTimestamp =
          secondTimestamp.add(
        const Duration(seconds: 20),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1400,
          longitude: 101.6900,
          timestamp: firstTimestamp,
        ),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1410,
          longitude: 101.6900,
          timestamp: secondTimestamp,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      final currentPace =
          controller.currentPaceSecondsPerKm;

      final averagePace =
          controller.averagePaceSecondsPerKm;

      controller.pause();

      locationService.emit(
        createPosition(
          latitude: 3.1500,
          longitude: 101.6900,
          timestamp: thirdTimestamp,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      expect(
        controller.currentPaceSecondsPerKm,
        currentPace,
      );

      expect(
        controller.averagePaceSecondsPerKm,
        closeTo(averagePace, 0.001),
      );
    },
  );

  test(
    'paused tracking should ignore GPS positions',
    () async {
      await controller.start();

      locationService.emit(
        createPosition(
          latitude: 3.1400,
          longitude: 101.6900,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      controller.pause();

      locationService.emit(
        createPosition(
          latitude: 3.1410,
          longitude: 101.6900,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      expect(
        controller.points,
        hasLength(1),
      );

      expect(
        controller.isPaused,
        isTrue,
      );
    },
  );

  test(
    'resumed tracking should accept GPS positions again',
    () async {
      await controller.start();

      final firstTimestamp =
          DateTime.utc(2026, 9, 10, 6);

      final secondTimestamp =
          firstTimestamp.add(
        const Duration(seconds: 20),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1400,
          longitude: 101.6900,
          timestamp: firstTimestamp,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      controller.pause();
      controller.resume();

      locationService.emit(
        createPosition(
          latitude: 3.1410,
          longitude: 101.6900,
          timestamp: secondTimestamp,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      expect(
        controller.points,
        hasLength(2),
      );

      expect(
        controller.isPaused,
        isFalse,
      );
    },
  );

  test(
    'GPS points with poor accuracy should be ignored',
    () async {
      await controller.start();

      final poorAccuracyPosition =
          createPosition(
        latitude: 3.1400,
        longitude: 101.6900,
        accuracy: 50,
      );

      locationService.emit(
        poorAccuracyPosition,
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      expect(
        controller.points,
        isEmpty,
      );

      expect(
        controller.distanceMeters,
        0,
      );
    },
  );

  test(
    'GPS points with older timestamps should be ignored',
    () async {
      await controller.start();

      final firstTimestamp =
          DateTime.utc(2026, 9, 10, 6);

      final secondTimestamp =
          firstTimestamp.subtract(
        const Duration(seconds: 1),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1400,
          longitude: 101.6900,
          timestamp: firstTimestamp,
        ),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1410,
          longitude: 101.6900,
          timestamp: secondTimestamp,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      expect(
        controller.points,
        hasLength(1),
      );
    },
  );

  test(
    'GPS jumps above maximum speed should be ignored',
    () async {
      await controller.start();

      final firstTimestamp =
          DateTime.utc(2026, 9, 10, 6);

      final secondTimestamp =
          firstTimestamp.add(
        const Duration(seconds: 1),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1400,
          longitude: 101.6900,
          timestamp: firstTimestamp,
        ),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1500,
          longitude: 101.6900,
          timestamp: secondTimestamp,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      expect(
        controller.points,
        hasLength(1),
      );

      expect(
        controller.distanceMeters,
        0,
      );
    },
  );

  test(
    'small GPS movement should not increase distance',
    () async {
      await controller.start();

      final firstTimestamp =
          DateTime.utc(2026, 9, 10, 6);

      final secondTimestamp =
          firstTimestamp.add(
        const Duration(seconds: 5),
      );

      locationService.emit(
        createPosition(
          latitude: 3.1400,
          longitude: 101.6900,
          timestamp: firstTimestamp,
        ),
      );

      locationService.emit(
        createPosition(
          latitude: 3.14001,
          longitude: 101.6900,
          timestamp: secondTimestamp,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      expect(
        controller.points,
        hasLength(2),
      );

      expect(
        controller.distanceMeters,
        0,
      );
    },
  );

  test(
    'stop should stop accepting GPS positions',
    () async {
      await controller.start();

      locationService.emit(
        createPosition(
          latitude: 3.1400,
          longitude: 101.6900,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      await controller.stop();

      locationService.emit(
        createPosition(
          latitude: 3.1410,
          longitude: 101.6900,
        ),
      );

      await Future<void>.delayed(
        Duration.zero,
      );

      expect(
        controller.points,
        hasLength(1),
      );

      expect(
        controller.isTracking,
        isFalse,
      );
    },
  );
}