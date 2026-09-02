import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/feed_models.dart';

class FeedService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  FeedService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<PagedFeedResponse> getFeed({
    int page = 1,
    int pageSize = 20,
  }) async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available.');
    }

    final queryParameters = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    final query = Uri(queryParameters: queryParameters).query;

    final response = await _apiClient.get(
      '/feed?$query',
      token: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load feed: '
        '${response.statusCode} ${response.body}',
      );
    }

    return PagedFeedResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void dispose() {
    _apiClient.dispose();
  }
}
