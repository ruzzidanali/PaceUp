class AuthResponse {
  final String userId;
  final String username;
  final String email;
  final String displayName;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const AuthResponse({
    required this.userId,
    required this.username,
    required this.email,
    required this.displayName,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['userId'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

class RegisterRequest {
  final String username;
  final String email;
  final String displayName;
  final String password;

  const RegisterRequest({
    required this.username,
    required this.email,
    required this.displayName,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'displayName': displayName,
      'password': password,
    };
  }
}

class RefreshTokenResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const RefreshTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

class RefreshTokenRequest {
  final String refreshToken;

  const RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken};
  }
}
