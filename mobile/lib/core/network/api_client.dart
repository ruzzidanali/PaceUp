import 'dart:convert';

import 'package:http/http.dart' as http;

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
