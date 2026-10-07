import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/auth_tokens.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  AuthException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AuthApi {
  static const _baseUrl = 'http://localhost:1337/api';

  Future<AuthTokens> login({required String email, required String password}) {
    return _post('/auth/local', {
      'identifier': email,
      'password': password,
    }, 'Accesso non riuscito');
  }

  Future<AuthTokens> register({
    required String username,
    required String email,
    required String password,
  }) {
    return _post('/auth/local/register', {
      'username': username,
      'email': email,
      'password': password,
    }, 'Registrazione non riuscita');
  }

  Future<AuthTokens> refresh(String refreshToken) {
    return _post('/auth/refresh', {
      'refreshToken': refreshToken,
    }, 'Sessione scaduta');
  }

  Future<AuthTokens> _post(
    String path,
    Map<String, dynamic> payload,
    String fallbackMessage,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final message =
          (body['error'] as Map<String, dynamic>?)?['message'] as String?;
      throw AuthException(
        message ?? fallbackMessage,
        statusCode: response.statusCode,
      );
    }

    return AuthTokens.fromJson(body);
  }
}
