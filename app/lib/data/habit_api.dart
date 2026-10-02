import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/habit.dart';

class HabitApi {
  static const _baseUrl = 'http://localhost:1337/api';
  final String token;

  HabitApi(this.token);

  Future<List<Habit>> fetchHabit() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/habits'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Errore ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['data'] as List;
    return list.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
  }
}
