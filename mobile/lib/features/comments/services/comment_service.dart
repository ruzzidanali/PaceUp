import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/comment_models.dart';

class CommentService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  CommentService({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<PagedCommentResponse> getComments(String activityId, {int page = 1, int pageSize = 20}) async {
    final token = await _getAccessToken();
    final response = await _apiClient.get('/activities/$activityId/comments?page=$page&pageSize=$pageSize', token: token);
    if (response.statusCode != 200) {
      throw Exception('Failed to load comments: ${response.statusCode} ${response.body}');
    }
    return PagedCommentResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<CommentResponse> createComment(String activityId, String content) async {
    final token = await _getAccessToken();
    final response = await _apiClient.post(
      '/activities/$activityId/comments',
      token: token,
      body: CreateCommentRequest(content: content).toJson(),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create comment: ${response.statusCode} ${response.body}');
    }
    return CommentResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteComment(String activityId, String commentId) async {
    final token = await _getAccessToken();
    final response = await _apiClient.delete('/activities/$activityId/comments/$commentId', token: token);
    if (response.statusCode != 204) {
      throw Exception('Failed to delete comment: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> _getAccessToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) throw Exception('No access token available.');
    return token;
  }

  void dispose() => _apiClient.dispose();
}
