import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/auth/data/auth_repository.dart';
import 'package:swarnbook/features/auth/data/models/auth_session.dart';
import 'package:swarnbook/features/auth/data/models/auth_user.dart';

/// Secure-storage key for the first-party access token.
const String authTokenStorageKey = 'swarnalekh_access_token';

/// Overridden in `main()` with the token restored from secure storage at
/// startup, so the first router redirect already knows if we're signed in
/// (no flash of the login screen).
final initialAuthTokenProvider = Provider<String?>((ref) => null);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

class AuthState {
  const AuthState({this.token, this.user});

  final String? token;
  final AuthUser? user;

  bool get isAuthenticated => token != null && token!.isNotEmpty;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    // 401s from any request mean the token is gone/expired — drop it so the
    // router bounces the user to /login.
    ApiClient.onUnauthorized = _onUnauthorized;

    final token = ref.read(initialAuthTokenProvider);
    if (token != null && token.isNotEmpty) {
      ApiClient().setAuthToken(token);
      return AuthState(token: token);
    }
    return const AuthState();
  }

  Future<void> login(String email, String password) async {
    final session = await ref
        .read(authRepositoryProvider)
        .login(email, password);
    await _apply(session);
  }

  Future<void> register(RegisterRequest request) async {
    final session = await ref.read(authRepositoryProvider).register(request);
    await _apply(session);
  }

  Future<void> logout() async {
    await _clearToken();
    state = const AuthState();
  }

  Future<void> _apply(AuthSession session) async {
    await _storage.write(key: authTokenStorageKey, value: session.accessToken);
    ApiClient().setAuthToken(session.accessToken);
    state = AuthState(token: session.accessToken, user: session.user);
  }

  Future<void> _clearToken() async {
    await _storage.delete(key: authTokenStorageKey);
    ApiClient().clearAuthToken();
  }

  void _onUnauthorized() {
    if (!state.isAuthenticated) return;
    // Fire-and-forget: clear persisted token, then reset state synchronously.
    _storage.delete(key: authTokenStorageKey);
    ApiClient().clearAuthToken();
    state = const AuthState();
  }
}
