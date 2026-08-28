class UserResponse {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? bio;
  final String? profileImageUrl;
  final DateTime createdAt;

  const UserResponse({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    required this.bio,
    required this.profileImageUrl,
    required this.createdAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      bio: json['bio'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class UpdateProfileRequest {
  final String displayName;
  final String? bio;

  const UpdateProfileRequest({required this.displayName, required this.bio});

  Map<String, dynamic> toJson() {
    return {'displayName': displayName, 'bio': bio};
  }
}

class UpdateProfileImageRequest {
  final String? profileImageUrl;

  const UpdateProfileImageRequest({required this.profileImageUrl});

  Map<String, dynamic> toJson() {
    return {'profileImageUrl': profileImageUrl};
  }
}
