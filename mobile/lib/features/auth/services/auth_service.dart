import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_models.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: request.toJson(),
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.statusCode} ${response.body}');
    }

    final authResponse = AuthResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    await _tokenStorage.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );

    return authResponse;
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _apiClient.post(
      '/auth/register',
      body: request.toJson(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Registration failed: ${response.statusCode} ${response.body}',
      );
    }

    final authResponse = AuthResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    await _tokenStorage.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );

    return authResponse;
  }

  Future<UserModel> getCurrentUser() async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    final response = await _apiClient.get('/users/me', token: accessToken);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get current user: '
        '${response.statusCode} ${response.body}',
      );
    }

    return UserModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<RefreshTokenResponse> refresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('No refresh token available.');
    }

    final response = await _apiClient.post(
      '/auth/refresh',
      body: RefreshTokenRequest(refreshToken: refreshToken).toJson(),
    );

    if (response.statusCode != 200) {
      await _tokenStorage.clear();

      throw Exception(
        'Token refresh failed: '
        '${response.statusCode} ${response.body}',
      );
    }

    final result = RefreshTokenResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    await _tokenStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );

    return result;
  }

  Future<void> revoke() async {
    final refreshToken = await _tokenStorage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      await _tokenStorage.clear();
      return;
    }

    final response = await _apiClient.post(
      '/auth/revoke',
      body: RefreshTokenRequest(refreshToken: refreshToken).toJson(),
    );

    await _tokenStorage.clear();

    if (response.statusCode != 204) {
      throw Exception(
        'Token revoke failed: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  Future<String?> getAccessToken() {
    return _tokenStorage.getAccessToken();
  }

  Future<void> logout() async {
    await revoke();
  }

  void dispose() {
    _apiClient.dispose();
  }
}
