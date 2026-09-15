import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/route_models.dart';

class RouteService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  RouteService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<RouteResponse> getRoute(String activityId) async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    final response = await _apiClient.get(
      '/activities/$activityId/route',
      token: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load activity route: '
        '${response.statusCode} ${response.body}',
      );
    }

    return RouteResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> createRoute(
    String activityId,
    CreateActivityRouteRequest request,
  ) async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    final response = await _apiClient.post(
      '/activities/$activityId/route',
      body: request.toJson(),
      token: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to upload activity route: '
        '${response.statusCode} ${response.body}',
      );
    }

    jsonDecode(response.body);
  }

  void dispose() {
    _apiClient.dispose();
  }
}
