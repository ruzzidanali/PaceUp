class ActivityResponse {
  final String id;
  final String userId;
  final String type;
  final double distance;
  final int durationSeconds;
  final int? calories;
  final DateTime startedAt;
  final DateTime createdAt;

  const ActivityResponse({
    required this.id,
    required this.userId,
    required this.type,
    required this.distance,
    required this.durationSeconds,
    required this.calories,
    required this.startedAt,
    required this.createdAt,
  });

  factory ActivityResponse.fromJson(Map<String, dynamic> json) {
    return ActivityResponse(
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

class PagedActivityResponse {
  final List<ActivityResponse> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const PagedActivityResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory PagedActivityResponse.fromJson(Map<String, dynamic> json) {
    return PagedActivityResponse(
      items: (json['items'] as List<dynamic>)
          .map(
            (item) => ActivityResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}

class ActivityStatsResponse {
  final int totalActivities;
  final double totalDistance;
  final int totalDurationSeconds;
  final int totalCalories;
  final Map<String, int> activitiesByType;

  const ActivityStatsResponse({
    required this.totalActivities,
    required this.totalDistance,
    required this.totalDurationSeconds,
    required this.totalCalories,
    required this.activitiesByType,
  });

  factory ActivityStatsResponse.fromJson(Map<String, dynamic> json) {
    final activitiesByTypeJson =
        json['activitiesByType'] as Map<String, dynamic>;

    return ActivityStatsResponse(
      totalActivities: json['totalActivities'] as int,
      totalDistance: (json['totalDistance'] as num).toDouble(),
      totalDurationSeconds: json['totalDurationSeconds'] as int,
      totalCalories: json['totalCalories'] as int,
      activitiesByType: activitiesByTypeJson.map(
        (key, value) => MapEntry(key, value as int),
      ),
    );
  }
}

class CreateActivityRequest {
  final String type;
  final double distance;
  final int durationSeconds;
  final int? calories;
  final DateTime startedAt;

  const CreateActivityRequest({
    required this.type,
    required this.distance,
    required this.durationSeconds,
    required this.calories,
    required this.startedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'distance': distance,
      'durationSeconds': durationSeconds,
      'calories': calories,
      'startedAt': startedAt.toUtc().toIso8601String(),
    };
  }
}

class UpdateActivityRequest {
  final String type;
  final double distance;
  final int durationSeconds;
  final int? calories;
  final DateTime startedAt;

  const UpdateActivityRequest({
    required this.type,
    required this.distance,
    required this.durationSeconds,
    required this.calories,
    required this.startedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'distance': distance,
      'durationSeconds': durationSeconds,
      'calories': calories,
      'startedAt': startedAt.toUtc().toIso8601String(),
    };
  }
}
