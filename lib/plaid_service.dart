import 'dart:convert';

import 'package:http/http.dart' as http;

class PlaidService {
  PlaidService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? const String.fromEnvironment('PLAID_API_BASE_URL');
      // clientId = clientId ?? const String.fromEnvironment('Client_ID_plaid'), , String? clientId, String? secret
      // secret = secret ?? const String.fromEnvironment('Secret_plaid');

  final http.Client _client;
  final String baseUrl;
  // final String clientId;
  // final String secret;

  Future<String> createLinkToken({required String userId}) async {
    if (baseUrl.isEmpty) {
      
      throw StateError('PLAID_API_BASE_URL is not configured.');
    }
    print("baseUrl: $baseUrl");
    final response = await _client.post(
      Uri.parse('$baseUrl/link/token/create'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'userId': userId}), //{'userId': userId}
    );
    print("response: ${response.body}");
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
