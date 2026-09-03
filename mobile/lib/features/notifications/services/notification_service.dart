import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/notification_models.dart';

class NotificationService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  NotificationService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<List<NotificationResponse>> getNotifications() async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.get(
      '/notifications',
      token: accessToken,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load notifications: '
        '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Invalid notifications response.');
    }

    return decoded
        .map(
          (item) => NotificationResponse.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.patch(
      '/notifications/$notificationId/read',
      token: accessToken,
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        'Failed to mark notification as read: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> markAllAsRead() async {
    final accessToken = await _getAccessToken();

    final response = await _apiClient.post(
      '/notifications/read-all',
      token: accessToken,
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        'Failed to mark all notifications as read: '
        '${response.statusCode} ${response.body}',
      );
    }
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
