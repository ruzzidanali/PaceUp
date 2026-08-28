import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/dashboard_models.dart';

class DashboardService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  DashboardService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<DashboardResponse> getDashboard() async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    final response = await _apiClient.get('/dashboard', token: accessToken);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load dashboard: '
        '${response.statusCode} ${response.body}',
      );
    }

    return DashboardResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void dispose() {
    _apiClient.dispose();
  }
}
