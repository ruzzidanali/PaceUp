import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_config.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<http.Response> get(String path, {String? token}) {
    return _client.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers(token),
    );
  }

  Future<http.Response> post(String path, {Object? body, String? token}) {
    return _client.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers(token),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> put(String path, {Object? body, String? token}) {
    return _client.put(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers(token),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> patch(String path, {Object? body, String? token}) {
    return _client.patch(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers(token),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> delete(String path, {String? token}) {
    return _client.delete(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers(token),
    );
  }

  Future<http.Response> postMultipart(
    String path, {
    required String fileField,
    required String filePath,
    String? contentType,
    String? token,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}$path'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    MediaType? mediaType;

    if (contentType != null && contentType.contains('/')) {
      final parts = contentType.split('/');

      mediaType = MediaType(parts[0], parts[1]);
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        fileField,
        filePath,
        contentType: mediaType,
      ),
    );

    final streamedResponse = await request.send();

    return http.Response.fromStream(streamedResponse);
  }

  Future<http.Response> putMultipart(
    String path, {
    required String fileField,
    required String filePath,
    String? contentType,
    String? token,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiConfig.baseUrl}$path'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    MediaType? mediaType;

    if (contentType != null && contentType.contains('/')) {
      final parts = contentType.split('/');

      mediaType = MediaType(parts[0], parts[1]);
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        fileField,
        filePath,
        contentType: mediaType,
      ),
    );

    final streamedResponse = await request.send();

    return http.Response.fromStream(streamedResponse);
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void dispose() {
    _client.close();
  }
}
