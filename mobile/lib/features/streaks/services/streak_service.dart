import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../../core/storage/token_storage.dart';
import '../models/streak_models.dart';

class StreakService {
  final TokenStorage _tokenStorage;

  StreakService({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage();

  Future<StreakResponse> getStreak() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/streaks'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load streak: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid streak response.');
    }

    return StreakResponse.fromJson(decoded);
  }
}