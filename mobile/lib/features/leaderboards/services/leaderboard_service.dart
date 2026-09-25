import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../../core/storage/token_storage.dart';
import '../models/leaderboard_models.dart';

class LeaderboardService {
  final TokenStorage _tokenStorage;

  LeaderboardService({
    TokenStorage? tokenStorage,
  }) : _tokenStorage = tokenStorage ?? TokenStorage();

  Future<List<LeaderboardEntryResponse>> getLeaderboard({
    String period = 'weekly',
    int limit = 10,
  }) async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/leaderboards',
    ).replace(
      queryParameters: {
        'period': period,
        'limit': limit.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load leaderboard: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Invalid leaderboard response.');
    }

    return decoded
        .map(
          (json) => LeaderboardEntryResponse.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}