import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../../../core/storage/token_storage.dart';
import '../models/personal_record_models.dart';

class PersonalRecordService {
  final TokenStorage _tokenStorage;

  PersonalRecordService({
    TokenStorage? tokenStorage,
  }) : _tokenStorage = tokenStorage ?? TokenStorage();

  Future<PersonalRecordResponse> getPersonalRecords() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/personal-records',
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
        'Failed to load personal records: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid personal records response.');
    }

    return PersonalRecordResponse.fromJson(decoded);
  }
}