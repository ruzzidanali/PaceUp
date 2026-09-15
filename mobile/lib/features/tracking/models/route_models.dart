class ActivityPointResponse {
  final String id;
  final String activityId;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? speed;
  final double? heartRate;
  final DateTime recordedAt;

  const ActivityPointResponse({
    required this.id,
    required this.activityId,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.speed,
    this.heartRate,
    required this.recordedAt,
  });

  factory ActivityPointResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ActivityPointResponse(
      id: json['id'] as String,
      activityId: json['activityId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heartRate: (json['heartRate'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(
        json['recordedAt'] as String,
      ),
    );
  }
}

class RouteResponse {
  final String activityId;
  final List<ActivityPointResponse> points;

  const RouteResponse({
    required this.activityId,
    required this.points,
  });

  factory RouteResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return RouteResponse(
      activityId: json['activityId'] as String,
      points: (json['points'] as List<dynamic>)
          .map(
            (point) => ActivityPointResponse.fromJson(
              point as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class CreateActivityPointRequest {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? speed;
  final double? heartRate;
  final DateTime recordedAt;

  const CreateActivityPointRequest({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.speed,
    this.heartRate,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'speed': speed,
      'heartRate': heartRate,
      'recordedAt': recordedAt.toUtc().toIso8601String(),
    };
  }
}

class CreateActivityRouteRequest {
  final List<CreateActivityPointRequest> points;

  const CreateActivityRouteRequest({
    required this.points,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((point) => point.toJson()).toList(),
    };
  }
}