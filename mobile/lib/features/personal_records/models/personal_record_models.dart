class PersonalRecordResponse {
  final double? longestDistanceKm;
  final int? longestDurationSeconds;
  final double? fastestSpeedKmh;
  final double? fastestPaceSecondsPerKm;
  final int? mostCalories;

  const PersonalRecordResponse({
    required this.longestDistanceKm,
    required this.longestDurationSeconds,
    required this.fastestSpeedKmh,
    required this.fastestPaceSecondsPerKm,
    required this.mostCalories,
  });

  factory PersonalRecordResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return PersonalRecordResponse(
      longestDistanceKm: (json['longestDistanceKm'] as num?)?.toDouble(),
      longestDurationSeconds:
          (json['longestDurationSeconds'] as num?)?.toInt(),
      fastestSpeedKmh: (json['fastestSpeedKmh'] as num?)?.toDouble(),
      fastestPaceSecondsPerKm:
          (json['fastestPaceSecondsPerKm'] as num?)?.toDouble(),
      mostCalories: (json['mostCalories'] as num?)?.toInt(),
    );
  }
}