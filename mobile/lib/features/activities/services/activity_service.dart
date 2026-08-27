import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/activity_models.dart';

class ActivityService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  ActivityService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<PagedActivityResponse> getActivities({
    int page = 1,
    int pageSize = 20,
    String? type,
    DateTime? from,
    DateTime? to,
  }) async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    final queryParameters = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (type != null && type.isNotEmpty) 'type': type,
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    };

    final query = Uri(queryParameters: queryParameters).query;

    final response = await _apiClient.get(
      '/activities?$query',
      token: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load activities: '
        '${response.statusCode} ${response.body}',
      );
    }

    return PagedActivityResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ActivityStatsResponse> getStats({
    String? type,
    DateTime? from,
    DateTime? to,
  }) async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    final queryParameters = <String, String>{
      if (type != null && type.isNotEmpty) 'type': type,
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    };

    final query = queryParameters.isEmpty
        ? ''
        : '?${Uri(queryParameters: queryParameters).query}';

    final response = await _apiClient.get(
      '/activities/stats$query',
      token: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load activity stats: '
        '${response.statusCode} ${response.body}',
      );
    }

    return ActivityStatsResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ActivityResponse> createActivity(CreateActivityRequest request) async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    final response = await _apiClient.post(
      '/activities',
      body: request.toJson(),
      token: accessToken,
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to create activity: '
        '${response.statusCode} ${response.body}',
      );
    }

    return ActivityResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void dispose() {
    _apiClient.dispose();
  }
}
