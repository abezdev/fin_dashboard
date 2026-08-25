import 'dart:convert';

import 'package:http/http.dart' as http;

class PlaidService {
  PlaidService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? const String.fromEnvironment('PLAID_API_BASE_URL');

  final http.Client _client;
  final String baseUrl;

  Future<String> createLinkToken({required String userId}) async {
    if (baseUrl.isEmpty) {
      throw StateError('PLAID_API_BASE_URL is not configured.');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/api/plaid/link-token'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Plaid link token request failed (${response.statusCode}).',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final linkToken = payload['link_token'];
    if (linkToken is! String || linkToken.isEmpty) {
      throw StateError('Plaid response did not include link_token.');
    }
    return linkToken;
  }
}
