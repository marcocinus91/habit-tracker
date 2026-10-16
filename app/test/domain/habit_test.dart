import 'package:app/domain/habit.dart';
import 'package:flutter_test/flutter_test.dart';

Habit _habit({List<int> days = const [], bool archived = false}) => Habit(
  id: 'x',
  name: 'Test',
  emoji: '🎯',
  color: '#4F8EF7',
  scheduledWeekdays: days,
  reminderTime: null,
  startDate: '2026-10-16',
  archived: archived,
);

void main() {
  final friday = DateTime(2026, 10, 16);

  test('lista vuota = ogni giorno', () {
    expect(_habit().isScheduledOn(friday), isTrue);
  });

  test('solo i giorni indicati', () {
    expect(_habit(days: [5]).isScheduledOn(friday), isTrue);
    expect(_habit(days: [2]).isScheduledOn(friday), isFalse);
  });

  test('non prima della startDate', () {
    expect(_habit().isScheduledOn(DateTime(2026, 10, 15)), isFalse);
  });

  test('archiviato mai previsto', () {
    expect(_habit(archived: true).isScheduledOn(friday), isFalse);
  });
}
