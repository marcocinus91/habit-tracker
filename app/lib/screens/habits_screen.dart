import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/habit.dart';
import '../state/providers.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Habit')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/habits/new'),
        child: const Icon(Icons.add),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Errore nel caricamento: $error'),
          ),
        ),
        data: (habits) {
          final active = habits.where((h) => !h.archived).toList();

          if (active.isEmpty) {
            return const Center(
              child: Text('Nessun habit ancora. Creane uno!'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(habitsProvider.future),
            child: ListView.builder(
              itemCount: active.length,
              itemBuilder: (context, index) => _HabitRow(habit: active[index]),
            ),
          );
        },
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final Habit habit;
  const _HabitRow({required this.habit});

  static const _dayLabels = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

  String get _daysText {
    if (habit.scheduledWeekdays.isEmpty ||
        habit.scheduledWeekdays.length == 7) {
      return 'Ogni giorno';
    }
    final days = [...habit.scheduledWeekdays]..sort();
    return days.map((d) => _dayLabels[d - 1]).join(', ');
  }

  Color get _color {
    final value = int.tryParse(habit.color.replaceFirst('#', '0xFF'));
    return value == null ? Colors.blue : Color(value);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _color.withValues(alpha: 0.2),
        child: Text(habit.emoji, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(habit.name),
      subtitle: Text(_daysText),
    );
  }
}
