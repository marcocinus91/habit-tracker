import 'dart:convert';

import 'package:app/data/api_client.dart';

import '../domain/habit.dart';

class HabitApi {
  final ApiClient _client;
  HabitApi(this._client);

  Future<List<Habit>> fetchHabits() async {
    final response = await _client.get('/habits');

    if (response.statusCode != 200) {
      throw Exception(
        'Errore ${response.statusCode} su ${response.request?.url}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['data'] as List;
    return list.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<String>> fetchLogDates(String habitId) async {
    final response = await _client.get('/habit-logs?habit=$habitId');

    if (response.statusCode != 200) {
      throw Exception(
        'Errore ${response.statusCode} su ${response.request?.url}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['data'] as List;
    return list
        .map((e) => (e as Map<String, dynamic>)['date'] as String)
        .toList();
  }
}
