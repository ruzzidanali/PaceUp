import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../../core/storage/token_storage.dart';
import '../models/achievement_models.dart';

class AchievementService {
  final TokenStorage _tokenStorage;

  AchievementService({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage();

  Future<List<AchievementResponse>> getAchievements() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/achievements'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load achievements: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Invalid achievements response.');
    }

    return decoded
        .map(
          (json) => AchievementResponse.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  List<AchievementResponse> findNewlyUnlocked(
    List<AchievementResponse> before,
    List<AchievementResponse> after,
  ) {
    final previouslyUnlocked = before
        .where((achievement) => achievement.isUnlocked)
        .map((achievement) => achievement.id)
        .toSet();

    return after
        .where(
          (achievement) =>
              achievement.isUnlocked &&
              !previouslyUnlocked.contains(achievement.id),
        )
        .toList();
  }
}
