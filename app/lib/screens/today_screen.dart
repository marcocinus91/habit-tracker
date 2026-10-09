import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/habit_api.dart';
import '../domain/habit.dart';
import '../domain/streak_calculator.dart';
import '../state/providers.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late final HabitApi _api = ref.read(habitApiProvider);
  late Future<List<_HabitWithStreak>> _habitsFuture;

  @override
  void initState() {
    super.initState();
    _habitsFuture = _loadHabits();
  }

  Future<List<_HabitWithStreak>> _loadHabits() async {
    final habits = await _api.fetchHabits();

    final results = <_HabitWithStreak>[];
    for (final habit in habits) {
      final dates = await _api.fetchLogDates(habit.id);
      final streak = calculateStreak(
        completedDates: dates,
        scheduledWeekdays: habit.scheduledWeekdays,
        today: DateTime.now(),
      );
      results.add(_HabitWithStreak(habit: habit, streak: streak));
    }
    return results;
  }

  Future<void> _refresh() async {
    setState(() {
      _habitsFuture = _loadHabits();
    });
    await _habitsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oggi'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<_HabitWithStreak>>(
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

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text('Nessun habit ancora. Creane uno!'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Text(
                    item.habit.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(item.habit.name),
                  trailing: Text('🔥 ${item.streak}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HabitWithStreak {
  final Habit habit;
  final int streak;

  _HabitWithStreak({required this.habit, required this.streak});
}
