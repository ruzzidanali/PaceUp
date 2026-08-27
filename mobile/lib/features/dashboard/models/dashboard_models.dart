class DashboardResponse {
  final DashboardActivitySummary activitySummary;
  final List<DashboardActivity> recentActivities;
  final List<DashboardGoal> activeGoals;

  const DashboardResponse({
    required this.activitySummary,
    required this.recentActivities,
    required this.activeGoals,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      activitySummary: DashboardActivitySummary.fromJson(
        json['activitySummary'] as Map<String, dynamic>,
      ),
      recentActivities: (json['recentActivities'] as List<dynamic>)
          .map(
            (item) => DashboardActivity.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      activeGoals: (json['activeGoals'] as List<dynamic>)
          .map((item) => DashboardGoal.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardActivitySummary {
  final int totalActivities;
  final double totalDistance;
  final int totalDurationSeconds;
  final int totalCalories;

  const DashboardActivitySummary({
    required this.totalActivities,
    required this.totalDistance,
    required this.totalDurationSeconds,
    required this.totalCalories,
  });

  factory DashboardActivitySummary.fromJson(Map<String, dynamic> json) {
    return DashboardActivitySummary(
      totalActivities: json['totalActivities'] as int,
      totalDistance: (json['totalDistance'] as num).toDouble(),
      totalDurationSeconds: json['totalDurationSeconds'] as int,
      totalCalories: json['totalCalories'] as int,
    );
  }
}

class DashboardActivity {
  final String id;
  final String userId;
  final String type;
  final double distance;
  final int durationSeconds;
  final int? calories;
  final DateTime startedAt;
  final DateTime createdAt;

  const DashboardActivity({
    required this.id,
    required this.userId,
    required this.type,
    required this.distance,
    required this.durationSeconds,
    required this.calories,
    required this.startedAt,
    required this.createdAt,
  });

  factory DashboardActivity.fromJson(Map<String, dynamic> json) {
    return DashboardActivity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      distance: (json['distance'] as num).toDouble(),
      durationSeconds: json['durationSeconds'] as int,
      calories: json['calories'] as int?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class DashboardGoal {
  final String id;
  final String type;
  final double target;
  final double current;
  final double remaining;
  final double progressPercentage;
  final bool isCompleted;
  final DateTime startDate;
  final DateTime endDate;

  const DashboardGoal({
    required this.id,
    required this.type,
    required this.target,
    required this.current,
    required this.remaining,
    required this.progressPercentage,
    required this.isCompleted,
    required this.startDate,
    required this.endDate,
  });

  factory DashboardGoal.fromJson(Map<String, dynamic> json) {
    return DashboardGoal(
      id: json['id'] as String,
      type: json['type'] as String,
      target: (json['target'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
      isCompleted: json['isCompleted'] as bool,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }
}
