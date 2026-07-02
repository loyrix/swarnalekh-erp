import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/auth/data/models/auth_session.dart';

/// Payload for POST /auth/register — creates the shop + owner in one step.
class RegisterRequest {
  const RegisterRequest({
    required this.shopName,
    required this.ownerName,
    required this.email,
    required this.password,
    this.phone,
    this.city,
    this.state,
    this.gstin,
  });

  final String shopName;
  final String ownerName;
  final String email;
  final String password;
  final String? phone;
  final String? city;
  final String? state;
  final String? gstin;

  Map<String, dynamic> toJson() {
    String? nn(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
    return {
      'shopName': shopName.trim(),
      'ownerName': ownerName.trim(),
      'email': email.trim(),
      'password': password,
      if (nn(phone) != null) 'phone': nn(phone),
      if (nn(city) != null) 'city': nn(city),
      if (nn(state) != null) 'state': nn(state),
      if (nn(gstin) != null) 'gstin': nn(gstin),
    };
  }
}

class AuthRepository {
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  final ApiClient _api = ApiClient();

  Future<AuthSession> login(String email, String password) async {
    final response = await _api.dio.post(
      '/auth/login',
      data: {'email': email.trim(), 'password': password},
    );
    return AuthSession.fromJson((response.data as Map).cast<String, dynamic>());
  }

  Future<AuthSession> register(RegisterRequest request) async {
    final response = await _api.dio.post(
      '/auth/register',
      data: request.toJson(),
    );
    return AuthSession.fromJson((response.data as Map).cast<String, dynamic>());
  }
}
