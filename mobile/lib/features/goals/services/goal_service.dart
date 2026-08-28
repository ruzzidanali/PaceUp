import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/goal_models.dart';

class GoalService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  GoalService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<List<GoalResponse>> getGoals() async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    final response = await _apiClient.get('/goals', token: accessToken);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load goals: '
        '${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;

    return data
        .map((item) => GoalResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<GoalResponse> getGoal(String id) async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    final response = await _apiClient.get('/goals/$id', token: accessToken);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load goal: '
        '${response.statusCode} ${response.body}',
      );
    }

    return GoalResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<GoalProgressResponse> getProgress(String id) async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    final response = await _apiClient.get(
      '/goals/$id/progress',
      token: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load goal progress: '
        '${response.statusCode} ${response.body}',
      );
    }

    return GoalProgressResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<GoalResponse> createGoal(CreateGoalRequest request) async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    final response = await _apiClient.post(
      '/goals',
      body: request.toJson(),
      token: accessToken,
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to create goal: '
        '${response.statusCode} ${response.body}',
      );
    }

    return GoalResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<GoalResponse> updateGoal(String id, UpdateGoalRequest request) async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    final response = await _apiClient.put(
      '/goals/$id',
      body: request.toJson(),
      token: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update goal: '
        '${response.statusCode} ${response.body}',
      );
    }

    return GoalResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteGoal(String id) async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    final response = await _apiClient.delete('/goals/$id', token: accessToken);

    if (response.statusCode != 204) {
      throw Exception(
        'Failed to delete goal: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}
