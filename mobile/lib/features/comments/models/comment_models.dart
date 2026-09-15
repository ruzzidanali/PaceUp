class CommentResponse {
  final String id;
  final String activityId;
  final String userId;
  final String username;
  final String displayName;
  final String? profileImageUrl;
  final String content;
  final DateTime createdAt;

  const CommentResponse({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.profileImageUrl,
    required this.content,
    required this.createdAt,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) {
    return CommentResponse(
      id: json['id'] as String,
      activityId: json['activityId'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}