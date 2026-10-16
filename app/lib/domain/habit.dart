import 'package:app/domain/date_format.dart';

class Habit {
  final String id;
  final String name;
  final String emoji;
  final String color;
  final List<int> scheduledWeekdays;
  final String? reminderTime;
  final String startDate;
  final bool archived;

  const Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.scheduledWeekdays,
    required this.reminderTime,
    required this.startDate,
    required this.archived,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['documentId'] as String,
      name: json['name'] as String,
      emoji: (json['emoji'] as String?) ?? '',
      color: (json['color'] as String?) ?? '#4F8EF7',
      scheduledWeekdays: ((json['scheduledWeekdays'] as List?) ?? [])
          .cast<int>(),
      reminderTime: json['reminderTime'] as String?,
      startDate: json['startDate'] as String,
      archived: (json['archived'] as bool?) ?? false,
    );
  }

  bool isScheduledOn(DateTime day) {
    if (archived) return false;
    if (formatDate(day).compareTo(startDate) < 0) return false;
    return scheduledWeekdays.isEmpty || scheduledWeekdays.contains(day.weekday);
  }
}
