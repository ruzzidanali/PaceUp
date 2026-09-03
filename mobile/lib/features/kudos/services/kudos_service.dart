import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/kudos_models.dart';

class KudosService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  KudosService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<KudosResponse> getKudos(String activityId) async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.get(
      '/activities/$activityId/kudos',
      token: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load kudos: '
        '${response.statusCode} ${response.body}',
      );
    }

    return KudosResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<KudosResponse> giveKudos(String activityId) async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.post(
      '/activities/$activityId/kudos',
      token: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to give kudos: '
        '${response.statusCode} ${response.body}',
      );
    }

    return KudosResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<KudosResponse> removeKudos(String activityId) async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.delete(
      '/activities/$activityId/kudos',
      token: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to remove kudos: '
        '${response.statusCode} ${response.body}',
      );
    }

    return KudosResponse.fromJson(
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