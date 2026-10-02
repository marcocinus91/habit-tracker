import 'package:flutter/material.dart';

import 'data/habit_api.dart';
import 'domain/habit.dart';

void main() {
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F8EF7)),
      ),
      home: const TodayScreen(),
    );
  }
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  static const _token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIzIiwic2Vzc2lvbklkIjoiNDgwOGUxMjBkMDgwMjIwMzFmMTQ5OWU1Y2Y0MDkzMDQiLCJ0eXBlIjoiYWNjZXNzIiwiaWF0IjoxNzkwOTQ5ODcwLCJleHAiOjE3OTA5NTA0NzB9.ML1KsaKWgm-CUYuItJTgrsPS6LUyv4kU7Lum_l3neJM';

  late final HabitApi _api = HabitApi(_token);
  late Future<List<Habit>> _habitsFuture;

  @override
  void initState() {
    super.initState();
    _habitsFuture = _api.fetchHabit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oggi')),
      body: FutureBuilder(
        future: _habitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Errore nel caricamento: ${snapshot.error}'),
              ),
            );
          }

          final habits = snapshot.data ?? [];
          if (habits.isEmpty) {
            return const Center(
              child: Text('Nessun habit ancora. Creane uno!'),
            );
          }

          return ListView.builder(
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return ListTile(
                leading: Text(
                  habit.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(habit.name),
              );
            },
          );
        },
      ),
    );
  }
}
