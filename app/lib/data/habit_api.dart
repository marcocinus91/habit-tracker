import 'dart:convert';

import '../domain/habit.dart';
import '../domain/habit_log.dart';
import 'api_client.dart';

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

  Future<List<HabitLog>> fetchLogs(String habitId) async {
    final response = await _client.get('/habit-logs?habit=$habitId');

    if (response.statusCode != 200) {
      throw Exception(
        'Errore ${response.statusCode} su ${response.request?.url}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['data'] as List;
    return list
        .map((e) => HabitLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HabitLog?> createLog(String habitId, String date) async {
    final response = await _client.post(
      '/habit-logs',
      body: {
        'data': {'habit': habitId, 'date': date},
      },
    );

    if (response.statusCode == 409) return null;
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Errore ${response.statusCode} su ${response.request?.url}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'];

    final json = (data is List ? data.first : data) as Map<String, dynamic>;
    return HabitLog.fromJson(json);
  }

  Future<void> deleteLog(String logId) async {
    final response = await _client.delete('/habit-logs/$logId');

    if (response.statusCode == 404) return;
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Errore ${response.statusCode} su ${response.request?.url}',
      );
    }
  }

  Future<Habit> createHabit({
    required String name,
    required String emoji,
    required String color,
    required List<int> scheduledWeekdays,
    required String startDate,
  }) async {
    final response = await _client.post(
      '/habits',
      body: {
        'data': {
          'name': name,
          'emoji': emoji,
          'color': color,
          'scheduledWeekdays': scheduledWeekdays,
          'reminderTime': null,
          'startDate': startDate,
        },
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Errore ${response.statusCode} su ${response.request?.url}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Habit.fromJson(body['data'] as Map<String, dynamic>);
  }
}
