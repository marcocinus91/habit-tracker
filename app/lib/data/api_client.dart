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

  Future<http.Response> get(String path) async {
    var response = await _send(path, readToken());

    if (response.statusCode == 401) {
      final newToken = await refreshToken();
      if (newToken == null) throw SessionExpiredException();
      response = await _send(path, newToken);
    }
    return response;
  }

  Future<http.Response> _send(String path, String? token) {
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
  }
}
