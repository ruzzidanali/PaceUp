class NotificationResponse {
  final String id;
  final String type;
  final bool isRead;
  final String actorUserId;
  final String actorUsername;
  final String actorDisplayName;
  final String? actorProfileImageUrl;
  final DateTime createdAt;

  const NotificationResponse({
    required this.id,
    required this.type,
    required this.isRead,
    required this.actorUserId,
    required this.actorUsername,
    required this.actorDisplayName,
    required this.actorProfileImageUrl,
    required this.createdAt,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      id: json['id'] as String,
      type: json['type'] as String,
      isRead: json['isRead'] as bool,
      actorUserId: json['actorUserId'] as String,
      actorUsername: json['actorUsername'] as String,
      actorDisplayName: json['actorDisplayName'] as String,
      actorProfileImageUrl: json['actorProfileImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  NotificationResponse copyWith({
    bool? isRead,
  }) {
    return NotificationResponse(
      id: id,
      type: type,
      isRead: isRead ?? this.isRead,
      actorUserId: actorUserId,
      actorUsername: actorUsername,
      actorDisplayName: actorDisplayName,
      actorProfileImageUrl: actorProfileImageUrl,
      createdAt: createdAt,
    );
  }
}
