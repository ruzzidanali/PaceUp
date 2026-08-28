import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/challenge_models.dart';

class ChallengeService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  ChallengeService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<List<ChallengeResponse>> getChallenges() async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.get('/challenges', token: accessToken);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load challenges: '
        '${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as List<dynamic>;

    return json
        .map((item) => ChallengeResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChallengeResponse> getChallenge(String id) async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.get(
      '/challenges/$id',
      token: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load challenge: '
        '${response.statusCode} ${response.body}',
      );
    }

    return ChallengeResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ChallengeResponse> createChallenge(
    CreateChallengeRequest request,
  ) async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.post(
      '/challenges',
      body: request.toJson(),
      token: accessToken,
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to create challenge: '
        '${response.statusCode} ${response.body}',
      );
    }

    return ChallengeResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ChallengeResponse> updateChallenge(
    String id,
    UpdateChallengeRequest request,
  ) async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.put(
      '/challenges/$id',
      body: request.toJson(),
      token: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update challenge: '
        '${response.statusCode} ${response.body}',
      );
    }

    return ChallengeResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteChallenge(String id) async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.delete(
      '/challenges/$id',
      token: accessToken,
    );

    if (response.statusCode != 204) {
      throw Exception(
        'Failed to delete challenge: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> joinChallenge(String id) async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.post(
      '/challenges/$id/join',
      token: accessToken,
    );

    if (response.statusCode != 204) {
      throw Exception(
        'Failed to join challenge: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> leaveChallenge(String id) async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.delete(
      '/challenges/$id/join',
      token: accessToken,
    );

    if (response.statusCode != 204) {
      throw Exception(
        'Failed to leave challenge: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  Future<ChallengeProgressResponse?> getProgress(String id) async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.get(
      '/challenges/$id/progress',
      token: accessToken,
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load challenge progress: '
        '${response.statusCode} ${response.body}',
      );
    }

    return ChallengeProgressResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ChallengeLeaderboardResponse?> getLeaderboard(String id) async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.get(
      '/challenges/$id/leaderboard',
      token: accessToken,
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load challenge leaderboard: '
        '${response.statusCode} ${response.body}',
      );
    }

    return ChallengeLeaderboardResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<String> _getAccessToken() async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    return accessToken;
  }

  void dispose() {
    _apiClient.dispose();
  }
}
