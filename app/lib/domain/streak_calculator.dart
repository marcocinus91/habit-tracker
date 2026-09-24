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
      final key = _formatDate(cursor);
      if (completedSet.contains(key)) {
        streak++;
        isFirstScheduledDay = false;
      } else if (isFirstScheduledDay) {
        isFirstScheduledDay = false;
      } else {
        break;
      }
    }

    cursor = cursor.subtract(const Duration(days: 1));
  }

  return streak;
}

String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');

  return '$y-$m-$d';
}
