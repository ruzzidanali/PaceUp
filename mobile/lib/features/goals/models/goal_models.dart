class GoalResponse {
  final String id;
  final String userId;
  final String type;
  final double target;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalResponse({
    required this.id,
    required this.userId,
    required this.type,
    required this.target,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoalResponse.fromJson(Map<String, dynamic> json) {
    return GoalResponse(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      target: (json['target'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class GoalProgressResponse {
  final String goalId;
  final String type;
  final double target;
  final double current;
  final double remaining;
  final double progressPercentage;
  final bool isCompleted;

  const GoalProgressResponse({
    required this.goalId,
    required this.type,
    required this.target,
    required this.current,
    required this.remaining,
    required this.progressPercentage,
    required this.isCompleted,
  });

  factory GoalProgressResponse.fromJson(Map<String, dynamic> json) {
    return GoalProgressResponse(
      goalId: json['goalId'] as String,
      type: json['type'] as String,
      target: (json['target'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
      isCompleted: json['isCompleted'] as bool,
    );
  }
}

class CreateGoalRequest {
  final String type;
  final double target;
  final DateTime startDate;
  final DateTime endDate;

  const CreateGoalRequest({
    required this.type,
    required this.target,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'target': target,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
    };
  }
}

class UpdateGoalRequest {
  final String type;
  final double target;
  final DateTime startDate;
  final DateTime endDate;

  const UpdateGoalRequest({
    required this.type,
    required this.target,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'target': target,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
    };
  }
}
