import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/date_format.dart';
import '../domain/habit.dart';
import '../domain/habit_log.dart';
import '../domain/streak_calculator.dart';
import '../state/providers.dart';

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

          final now = DateTime.now();
          final todayHabits = habits
              .where((h) => h.isScheduledOn(now))
              .toList();

          if (todayHabits.isEmpty) {
            return const Center(child: Text('Niente in programma per oggi.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(habitLogsProvider);
              await ref.refresh(habitsProvider.future);
            },
            child: ListView.builder(
              itemCount: todayHabits.length,
              itemBuilder: (context, index) =>
                  _HabitTile(habit: todayHabits[index]),
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

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    HabitLog? todayLog,
    String today,
  ) async {
    final notifier = ref.read(habitLogsProvider(habit.id).notifier);
    try {
      if (todayLog == null) {
        await notifier.check(today);
      } else {
        await notifier.uncheck(todayLog);
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operazione non riuscita, riprova.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(habitLogsProvider(habit.id));
    final logs = logsAsync.value; // null finché non ci sono dati
    final today = formatDate(DateTime.now());
    final todayLog = logs?.where((l) => l.date == today).firstOrNull;

    final streakText = logs == null
        ? (logsAsync.hasError ? '-' : '...')
        : '🔥 ${calculateStreak(completedDates: logs.map((l) => l.date).toList(), scheduledWeekdays: habit.scheduledWeekdays, today: DateTime.now())}';

    return ListTile(
      leading: Text(habit.emoji, style: const TextStyle(fontSize: 24)),
      title: Text(habit.name),
      subtitle: Text(streakText),
      trailing: Checkbox(
        value: todayLog != null,
        onChanged: logs == null
            ? null
            : (_) => _toggle(context, ref, todayLog, today),
      ),
      onTap: logs == null ? null : () => _toggle(context, ref, todayLog, today),
    );
  }
}
