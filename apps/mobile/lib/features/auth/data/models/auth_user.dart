// Typed authenticated-user profile returned by /auth/login and /auth/register.

String? _s(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.shopName,
    required this.subscriptionPlan,
  });

  final String id;
  final String tenantId;
  final String name;
  final String? email;
  final String? phone;
  final String role;
  final String? shopName;
  final String? subscriptionPlan;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final tenant = json['tenant'];
    final tenantMap = tenant is Map ? tenant.cast<String, dynamic>() : const {};
    return AuthUser(
      id: (json['id'] ?? '').toString(),
      tenantId: (json['tenantId'] ?? tenantMap['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: _s(json['email']),
      phone: _s(json['phone']),
      role: (json['role'] ?? 'staff').toString(),
      shopName: _s(tenantMap['shopName']),
      subscriptionPlan: _s(tenantMap['subscriptionPlan']),
    );
  }
}
