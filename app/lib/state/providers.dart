import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/habit_api.dart';
import '../data/token_storage.dart';

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
