import 'package:app/domain/date_format.dart';

int calculateStreak({
  required List<String> completedDates,
  required List<int> scheduledWeekdays,
  required DateTime today,
}) {
  final completedSet = completedDates.toSet();
  var streak = 0;
  var cursor = DateTime(today.year, today.month, today.day);
  var isFirstScheduledDay = true;

  while (true) {
    final isScheduled =
        scheduledWeekdays.isEmpty || scheduledWeekdays.contains(cursor.weekday);

    if (isScheduled) {
      final key = formatDate(cursor);
      if (completedSet.contains(key)) {
        streak++;
        isFirstScheduledDay = false;
      } else if (isFirstScheduledDay) {
        isFirstScheduledDay = false;
      } else {
        break;
      }
    }

    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }

  return streak;
}
