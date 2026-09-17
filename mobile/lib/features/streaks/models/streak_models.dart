class StreakResponse {
  final int currentStreak;
  final int longestStreak;

  const StreakResponse({
    required this.currentStreak,
    required this.longestStreak,
  });

  factory StreakResponse.fromJson(Map<String, dynamic> json) {
    return StreakResponse(
      currentStreak: (json['currentStreak'] as num).toInt(),
      longestStreak: (json['longestStreak'] as num).toInt(),
    );
  }
}
