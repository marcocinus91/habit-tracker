import 'package:app/domain/streak_calculator.dart';
import 'package:app/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/habit.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Oggi')),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Errore nel caricamento: $error'),
          ),
        ),
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(
              child: Text('Nessun habit ancora. Creane uno!'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(habitLogDatesProvider);
              await ref.refresh(habitsProvider.future);
            },
            child: ListView.builder(
              itemCount: habits.length,
              itemBuilder: (context, index) => _HabitTile(habit: habits[index]),
            ),
          );
        },
      ),
    );
  }
}

class _HabitTile extends ConsumerWidget {
  final Habit habit;
  const _HabitTile({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(habitLogDatesProvider(habit.id));

    final streakText = logsAsync.when(
      loading: () => '...',
      error: (_, _) => '-',
      data: (dates) {
        final streak = calculateStreak(
          completedDates: dates,
          scheduledWeekdays: habit.scheduledWeekdays,
          today: DateTime.now(),
        );
        return '🔥 $streak';
      },
    );

    return ListTile(
      leading: Text(habit.emoji, style: const TextStyle(fontSize: 24)),
      title: Text(habit.name),
      trailing: Text(streakText),
    );
  }
}
