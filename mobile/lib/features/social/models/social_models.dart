class FollowUser {
  final String userId;
  final String username;
  final String displayName;
  final String? profileImageUrl;
  final DateTime followedAt;

  const FollowUser({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.profileImageUrl,
    required this.followedAt,
  });

  factory FollowUser.fromJson(Map<String, dynamic> json) {
    return FollowUser(
      userId: json['userId'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      followedAt: DateTime.parse(json['followedAt'] as String),
    );
  }
}

class FollowListResponse {
  final List<FollowUser> users;
  final int totalCount;

  const FollowListResponse({required this.users, required this.totalCount});

  factory FollowListResponse.fromJson(Map<String, dynamic> json) {
    final usersJson = json['users'] as List<dynamic>;

    return FollowListResponse(
      users: usersJson
          .map((item) => FollowUser.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
    );
  }
}

class FollowStatusResponse {
  final bool isFollowing;

  const FollowStatusResponse({required this.isFollowing});

  factory FollowStatusResponse.fromJson(Map<String, dynamic> json) {
    return FollowStatusResponse(isFollowing: json['isFollowing'] as bool);
  }
}

class UserSearchResult {
  final String id;
  final String username;
  final String displayName;
  final String? profileImageUrl;

  const UserSearchResult({
    required this.id,
    required this.username,
    required this.displayName,
    required this.profileImageUrl,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
