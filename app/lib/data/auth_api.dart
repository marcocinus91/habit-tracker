import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthApi {
  static const _baseUrl = 'http://localhost:1337/api';

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/local'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': email, 'password': password}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final message =
          (body['error'] as Map<String, dynamic>?)?['message'] as String?;
      throw AuthException(message ?? 'Accesso non riuscito');
    }

    return body['jwt'] as String;
  }

  Future<String> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/local/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final message =
          (body['error'] as Map<String, dynamic>?)?['message'] as String?;
      throw AuthException(message ?? 'Registrazione non riuscita');
    }

    return body['jwt'] as String;
  }
}
