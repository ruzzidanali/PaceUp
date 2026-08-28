class ChallengeResponse {
  final String id;
  final String createdByUserId;
  final String name;
  final String? description;
  final String type;
  final double targetValue;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final int participantCount;

  const ChallengeResponse({
    required this.id,
    required this.createdByUserId,
    required this.name,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.participantCount,
  });

  factory ChallengeResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeResponse(
      id: json['id'] as String,
      createdByUserId: json['createdByUserId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      targetValue: (json['targetValue'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      participantCount: json['participantCount'] as int,
    );
  }
}

class ChallengeProgressResponse {
  final String challengeId;
  final String userId;
  final String type;
  final double targetValue;
  final double currentValue;
  final double remainingValue;
  final double progressPercentage;
  final bool isCompleted;

  const ChallengeProgressResponse({
    required this.challengeId,
    required this.userId,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.remainingValue,
    required this.progressPercentage,
    required this.isCompleted,
  });

  factory ChallengeProgressResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeProgressResponse(
      challengeId: json['challengeId'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      targetValue: (json['targetValue'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      remainingValue: (json['remainingValue'] as num).toDouble(),
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
      isCompleted: json['isCompleted'] as bool,
    );
  }
}

class ChallengeParticipantResponse {
  final String userId;
  final String username;
  final String displayName;
  final String? profileImageUrl;
  final double currentValue;
  final int rank;

  const ChallengeParticipantResponse({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.profileImageUrl,
    required this.currentValue,
    required this.rank,
  });

  factory ChallengeParticipantResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipantResponse(
      userId: json['userId'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      currentValue: (json['currentValue'] as num).toDouble(),
      rank: json['rank'] as int,
    );
  }
}

class ChallengeLeaderboardResponse {
  final String challengeId;
  final List<ChallengeParticipantResponse> participants;

  const ChallengeLeaderboardResponse({
    required this.challengeId,
    required this.participants,
  });

  factory ChallengeLeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeLeaderboardResponse(
      challengeId: json['challengeId'] as String,
      participants: (json['participants'] as List<dynamic>)
          .map(
            (item) => ChallengeParticipantResponse.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class CreateChallengeRequest {
  final String name;
  final String? description;
  final String type;
  final double targetValue;
  final DateTime startDate;
  final DateTime endDate;

  const CreateChallengeRequest({
    required this.name,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'targetValue': targetValue,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
    };
  }
}

class UpdateChallengeRequest {
  final String name;
  final String? description;
  final String type;
  final double targetValue;
  final DateTime startDate;
  final DateTime endDate;

  const UpdateChallengeRequest({
    required this.name,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'targetValue': targetValue,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
    };
  }
}
