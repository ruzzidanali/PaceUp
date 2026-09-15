class TrackingPoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? speed;
  final double? heartRate;
  final DateTime recordedAt;

  const TrackingPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.speed,
    this.heartRate,
    required this.recordedAt,
  });
}