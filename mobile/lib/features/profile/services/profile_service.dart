import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/profile_models.dart';

import 'package:image_picker/image_picker.dart';

class ProfileService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  ProfileService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<String> _getAccessToken() async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    return accessToken;
  }

  Future<UserResponse> getMe() async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.get('/users/me', token: accessToken);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load profile: '
        '${response.statusCode} ${response.body}',
      );
    }

    return UserResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<UserResponse> getUser(String userId) async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.get('/users/$userId', token: accessToken);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load user profile: '
        '${response.statusCode} ${response.body}',
      );
    }

    return UserResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<UserResponse> updateProfile(UpdateProfileRequest request) async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.put(
      '/users/me',
      body: request.toJson(),
      token: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update profile: '
        '${response.statusCode} ${response.body}',
      );
    }

    return UserResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<UserResponse> updateProfileImage(XFile image) async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    final response = await _apiClient.postMultipart(
      '/users/me/profile-image',
      fileField: 'file',
      filePath: image.path,
      contentType: image.mimeType ?? 'image/jpeg',
      token: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update profile image: '
        '${response.statusCode} ${response.body}',
      );
    }

    return UserResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteAccount() async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.delete('/users/me', token: accessToken);

    if (response.statusCode != 204) {
      throw Exception(
        'Failed to delete account: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}
