class FeedActivityResponse {
  final String id;
  final String userId;
  final String username;
  final String displayName;
  final String? profileImageUrl;
  final String type;
  final double distance;
  final int durationSeconds;
  final int? calories;
  final DateTime startedAt;
  final DateTime createdAt;

  const FeedActivityResponse({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.profileImageUrl,
    required this.type,
    required this.distance,
    required this.durationSeconds,
    required this.calories,
    required this.startedAt,
    required this.createdAt,
  });

  factory FeedActivityResponse.fromJson(Map<String, dynamic> json) {
    return FeedActivityResponse(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      type: json['type'] as String,
      distance: (json['distance'] as num).toDouble(),
      durationSeconds: json['durationSeconds'] as int,
      calories: json['calories'] as int?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PagedFeedResponse {
  final List<FeedActivityResponse> activities;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const PagedFeedResponse({
    required this.activities,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory PagedFeedResponse.fromJson(Map<String, dynamic> json) {
    return PagedFeedResponse(
      activities: (json['activities'] as List<dynamic>)
          .map(
            (item) => FeedActivityResponse.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
