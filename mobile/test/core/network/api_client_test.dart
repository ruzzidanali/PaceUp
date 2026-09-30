import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:mobile/core/network/api_client.dart';

void main() {
  late ApiClient apiClient;

  setUp(() {
    apiClient = ApiClient();
  });

  tearDown(() {
    apiClient.dispose();
  });

  test('getErrorMessage returns ProblemDetails detail', () {
    final response = http.Response(
      '{"status":400,"title":"Invalid request","detail":"Email is required."}',
      400,
    );

    final result = apiClient.getErrorMessage(response);

    expect(result, 'Email is required.');
  });

  test('getErrorMessage falls back to ProblemDetails title', () {
    final response = http.Response(
      '{"status":400,"title":"Invalid request"}',
      400,
    );

    final result = apiClient.getErrorMessage(response);

    expect(result, 'Invalid request');
  });

  test('getErrorMessage returns fallback for invalid response', () {
    final response = http.Response(
      'not-json',
      500,
    );

    final result = apiClient.getErrorMessage(
      response,
      fallback: 'Failed to load activities.',
    );

    expect(result, 'Failed to load activities.');
  });
}