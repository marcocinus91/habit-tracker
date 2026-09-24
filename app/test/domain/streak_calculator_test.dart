import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/streak_calculator.dart';

void main() {
  group('calculateStreak - habit giornaliero', () {
    test('nessun giorno completato -> streak 0', () {
      final streak = calculateStreak(
        completedDates: [],
        scheduledWeekdays: [],
        today: DateTime(2026, 9, 24),
      );
      expect(streak, 0);
    });

    test('3 giorni consecutivi fino ad oggi -> streak 3', () {
      final streak = calculateStreak(
        completedDates: ['2026-09-22', '2026-09-23', '2026-09-24'],
        scheduledWeekdays: [],
        today: DateTime(2026, 9, 24),
      );
      expect(streak, 3);
    });

    test('un giorno saltato nel mezzo interrompe lo streak', () {
      final streak = calculateStreak(
        completedDates: [
          '2026-09-20',
          '2026-09-21',
          '2026-09-23',
          '2026-09-24',
        ],
        scheduledWeekdays: [],
        today: DateTime(2026, 9, 24),
      );
      expect(streak, 2);
    });

    test('oggi non ancora completato', () {
      final streak = calculateStreak(
        completedDates: ['2026-09-22', '2026-09-23'],
        scheduledWeekdays: [],
        today: DateTime(2026, 9, 24),
      );
      expect(streak, 2);
    });
  });

  group('calculateStreak - habit con giorni specifici', () {
    test('salta un giorno non previsto senza interrompere lo streak', () {
      final streak = calculateStreak(
        completedDates: ['2026-09-21', '2026-09-23'],
        scheduledWeekdays: [1, 3, 5],
        today: DateTime(2026, 9, 23),
      );
      expect(streak, 2);
    });
  });
}
