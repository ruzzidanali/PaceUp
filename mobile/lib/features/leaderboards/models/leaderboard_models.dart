class LeaderboardEntryResponse {
  final int rank;
  final String userId;
  final String username;
  final String displayName;
  final String? profileImageUrl;
  final double distanceKm;
  final bool isCurrentUser;

  const LeaderboardEntryResponse({
    required this.rank,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.profileImageUrl,
    required this.distanceKm,
    required this.isCurrentUser,
  });

  factory LeaderboardEntryResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return LeaderboardEntryResponse(
      rank: json['rank'] as int,
      userId: json['userId'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      isCurrentUser: json['isCurrentUser'] as bool,
    );
  }
}