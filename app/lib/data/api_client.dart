import 'dart:convert';

import 'package:http/http.dart' as http;

class SessionExpiredException implements Exception {
  @override
  String toString() => 'Sessione scaduta';
}

class ApiClient {
  static const baseUrl = 'http://localhost:1337/api';

  final String? Function() readToken;
  final Future<String?> Function() refreshToken;

  ApiClient({required this.readToken, required this.refreshToken});

  Future<http.Response> get(String path) => _request('GET', path);

  Future<http.Response> post(String path, {Object? body}) =>
      _request('POST', path, body: body);

  Future<http.Response> delete(String path) => _request('DELETE', path);

  Future<http.Response> _request(
    String method,
    String path, {
    Object? body,
  }) async {
    var response = await _send(method, path, body, readToken());

    if (response.statusCode == 401) {
      final newToken = await refreshToken();
      if (newToken == null) throw SessionExpiredException();
      response = await _send(method, path, body, newToken);
    }
    return response;
  }

  Future<http.Response> _send(
    String method,
    String path,
    Object? body,
    String? token,
  ) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return http.Response.fromStream(await request.send());
  }
}
