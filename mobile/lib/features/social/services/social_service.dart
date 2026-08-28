import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/social_models.dart';

class SocialService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  SocialService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<String> _getAccessToken() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('No access token available.');
    }

    return token;
  }

  Future<FollowListResponse> getFollowers(String userId) async {
    final token = await _getAccessToken();

    final response = await _apiClient.get(
      '/users/$userId/followers',
      token: token,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load followers: '
        '${response.statusCode} ${response.body}',
      );
    }

    return FollowListResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<FollowListResponse> getFollowing(String userId) async {
    final token = await _getAccessToken();

    final response = await _apiClient.get(
      '/users/$userId/following',
      token: token,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load following: '
        '${response.statusCode} ${response.body}',
      );
    }

    return FollowListResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> follow(String userId) async {
    final token = await _getAccessToken();

    final response = await _apiClient.post(
      '/users/$userId/follow',
      token: token,
    );

    if (response.statusCode != 204) {
      throw Exception(
        'Failed to follow user: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> unfollow(String userId) async {
    final token = await _getAccessToken();

    final response = await _apiClient.delete(
      '/users/$userId/follow',
      token: token,
    );

    if (response.statusCode != 204) {
      throw Exception(
        'Failed to unfollow user: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  Future<bool> isFollowing(String userId) async {
    final token = await _getAccessToken();

    final response = await _apiClient.get(
      '/users/$userId/follow-status',
      token: token,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load follow status: '
        '${response.statusCode} ${response.body}',
      );
    }

    final result = FollowStatusResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    return result.isFollowing;
  }

  Future<List<UserSearchResult>> searchUsers(String query) async {
    final token = await _getAccessToken();

    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return [];
    }

    final response = await _apiClient.get(
      '/users/search?query=${Uri.encodeQueryComponent(trimmedQuery)}',
      token: token,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to search users: '
        '${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;

    return data
        .map((item) => UserSearchResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  void dispose() {
    // ApiClient is shared/stateless and does not require disposal.
  }
}
