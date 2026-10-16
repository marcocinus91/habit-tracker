import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/habit_api.dart';
import '../data/token_storage.dart';
import '../domain/habit.dart';
import '../domain/habit_log.dart';

final tokenStorageProvider = Provider((ref) => TokenStorage());
final authApiProvider = Provider((ref) => AuthApi());

/// Lo stato è l'access token: null = non loggato.
final authProvider = AsyncNotifierProvider<AuthNotifier, String?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<String?> {
  Future<String?>? _refreshing;

  TokenStorage get _storage => ref.read(tokenStorageProvider);
  AuthApi get _api => ref.read(authApiProvider);

  /// Eseguito all'avvio: se c'è un refresh token salvato, prova a rinnovare.
  /// Non lancia mai errori: in dubbio, si torna al login.
  @override
  Future<String?> build() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) return null;

    try {
      final tokens = await _api.refresh(refreshToken);
      await _storage.save(tokens);
      return tokens.accessToken;
    } on AuthException catch (e) {
      if (e.statusCode == 400 || e.statusCode == 401) await _storage.clear();
      return null;
    } catch (_) {
      return null; // rete assente: i token restano salvati per il prossimo avvio
    }
  }

  Future<void> login(String email, String password) async {
    final tokens = await _api.login(email: email, password: password);
    await _storage.save(tokens);
    state = AsyncData(tokens.accessToken);
  }

  Future<void> register(String username, String email, String password) async {
    final tokens = await _api.register(
      username: username,
      email: email,
      password: password,
    );
    await _storage.save(tokens);
    state = AsyncData(tokens.accessToken);
  }

  Future<void> logout() async {
    await _storage.clear();
    state = const AsyncData(null);
  }

  /// Chiamato dal client HTTP quando riceve 401.
  /// Se due richieste falliscono insieme, il rinnovo parte una volta sola:
  /// il refresh token è monouso, un secondo tentativo con lo stesso fallirebbe.
  Future<String?> refreshAccessToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) {
      state = const AsyncData(null);
      return null;
    }

    try {
      final tokens = await _api.refresh(refreshToken);
      await _storage.save(tokens);
      state = AsyncData(tokens.accessToken);
      return tokens.accessToken;
    } on AuthException catch (e) {
      if (e.statusCode == 400 || e.statusCode == 401) {
        await _storage.clear();
        state = const AsyncData(null); // l'app torna al login da sola
      }
      return null;
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    readToken: () => ref.read(authProvider).value,
    refreshToken: () => ref.read(authProvider.notifier).refreshAccessToken(),
  );
});

final habitApiProvider = Provider(
  (ref) => HabitApi(ref.watch(apiClientProvider)),
);

/// true/false: cambia solo a login/logout, non a ogni rinnovo del token.
final isLoggedInProvider = Provider<bool>(
  (ref) => ref.watch(authProvider.select((s) => s.value != null)),
);

class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  @override
  Future<List<Habit>> build() async {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    if (!isLoggedIn) return [];
    return ref.read(habitApiProvider).fetchHabits();
  }

  Future<Habit> create({
    required String name,
    required String emoji,
    required String color,
    required List<int> scheduledWeekdays,
    required String startDate,
  }) async {
    final created = await ref
        .read(habitApiProvider)
        .createHabit(
          name: name,
          emoji: emoji,
          color: color,
          scheduledWeekdays: scheduledWeekdays,
          startDate: startDate,
        );
    state = AsyncData([...state.value ?? [], created]);
    return created;
  }
}

final habitsProvider = AsyncNotifierProvider<HabitsNotifier, List<Habit>>(
  HabitsNotifier.new,
);

const _pendingId = 'pending';

class HabitLogsNotifier extends AsyncNotifier<List<HabitLog>> {
  HabitLogsNotifier(this.habitId);
  final String habitId;

  @override
  Future<List<HabitLog>> build() async {
    ref.watch(isLoggedInProvider);
    return ref.read(habitApiProvider).fetchLogs(habitId);
  }

  Future<void> check(String date) async {
    final previous = state.value ?? [];
    state = AsyncData([...previous, HabitLog(id: _pendingId, date: date)]);

    try {
      final created = await ref.read(habitApiProvider).createLog(habitId, date);
      if (created == null) {
        ref.invalidateSelf(); // 409: già fatto, ricarico per avere il suo id
        return;
      }
      state = AsyncData([...previous, created]);
    } catch (_) {
      state = AsyncData(previous); // rollback
      rethrow;
    }
  }

  Future<void> uncheck(HabitLog log) async {
    if (log.id == _pendingId) return; // creazione ancora in corso
    final previous = state.value ?? [];
    state = AsyncData(previous.where((l) => l.id != log.id).toList());

    try {
      await ref.read(habitApiProvider).deleteLog(log.id);
    } catch (_) {
      state = AsyncData(previous); // rollback
      rethrow;
    }
  }
}

final habitLogsProvider =
    AsyncNotifierProvider.family<HabitLogsNotifier, List<HabitLog>, String>(
      HabitLogsNotifier.new,
    );
