import 'package:swarnbook/features/auth/data/models/auth_user.dart';

/// A first-party session from /auth/login or /auth/register.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAt,
    required this.user,
  });

  final String accessToken;
  final int expiresAt;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return AuthSession(
      accessToken: (json['accessToken'] ?? '').toString(),
      expiresAt: json['expiresAt'] is num
          ? (json['expiresAt'] as num).toInt()
          : int.tryParse(json['expiresAt']?.toString() ?? '') ?? 0,
      user: AuthUser.fromJson(
        user is Map ? user.cast<String, dynamic>() : const {},
      ),
    );
  }
}
