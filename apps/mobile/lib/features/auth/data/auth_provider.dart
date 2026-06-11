import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:swarnbook/core/network/api_client.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(supabaseClientProvider).auth.onAuthStateChange;
});

final currentSessionProvider = Provider<Session?>((ref) {
  return ref.watch(authStateProvider).value?.session;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.read(supabaseClientProvider),
    ApiClient(), // Since ApiClient is currently instantiated on demand
  );
});

class AuthService {
  final SupabaseClient _supabase;
  final ApiClient _apiClient;
  bool? _registrationCache;
  String? _registrationCacheUserId;
  Future<bool>? _registrationCheckFuture;

  AuthService(this._supabase, this._apiClient);

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.session != null) {
      _apiClient.setAuthToken(res.session!.accessToken);
      _resetRegistrationCache();
    }
    return res;
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    final res = await _supabase.auth.signUp(email: email, password: password);
    if (res.session != null) {
      _apiClient.setAuthToken(res.session!.accessToken);
      _resetRegistrationCache();
    }
    return res;
  }

  Future<bool> checkRegistration() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      _resetRegistrationCache();
      return false;
    }

    final userId = session.user.id;
    if (_registrationCacheUserId == userId && _registrationCache != null) {
      return _registrationCache!;
    }

    if (_registrationCheckFuture != null) {
      return _registrationCheckFuture!;
    }

    _apiClient.setAuthToken(session.accessToken);
    _registrationCheckFuture = _fetchRegistrationStatus(userId);
    return _registrationCheckFuture!;
  }

  Future<bool> _fetchRegistrationStatus(String userId) async {
    try {
      await _apiClient.dio.get('/auth/me');
      _registrationCacheUserId = userId;
      _registrationCache = true;
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        _registrationCacheUserId = userId;
        _registrationCache = false;
        return false;
      }
      rethrow;
    } finally {
      _registrationCheckFuture = null;
    }
  }

  Future<void> registerTenant(Map<String, dynamic> data) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception(
        'You are not signed in. Verify the email in the current auth provider, then sign in again.',
      );
    }
    _apiClient.setAuthToken(session.accessToken);
    await _apiClient.dio.post('/tenant/register', data: data);
    _registrationCacheUserId = session.user.id;
    _registrationCache = true;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _apiClient.clearAuthToken();
    _resetRegistrationCache();
  }

  void _resetRegistrationCache() {
    _registrationCache = null;
    _registrationCacheUserId = null;
    _registrationCheckFuture = null;
  }
}
