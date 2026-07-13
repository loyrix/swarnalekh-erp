import 'package:swarnbook/core/network/api_client.dart';

class CurrentUserContext {
  final String? role;
  final String? userName;
  final String? shopName;

  const CurrentUserContext({this.role, this.userName, this.shopName});
}

bool isAdminRole(String? role) {
  final value = role?.trim().toLowerCase();
  return value == 'owner' || value == 'admin';
}

bool isStaffRole(String? role) => role?.trim().toLowerCase() == 'staff';

/// Admin-only shell routes. Staff must never land on these (they are hidden
/// from the nav, but can still be reached by direct URL on web).
const Set<String> kAdminOnlyRoutes = {
  '/reports',
  '/security',
  '/user-management',
  '/shop-profile',
  '/categories',
};

/// Pure guard: true when a user with [role] should be redirected away from
/// [location]. Kept side-effect free so it is unit-testable without a router.
bool isRestrictedRoute(String? role, String location) =>
    isStaffRole(role) && kAdminOnlyRoutes.contains(location);

Future<String?> fetchCurrentUserRole(ApiClient api) async {
  final context = await fetchCurrentUserContext(api);
  return context.role;
}

Future<CurrentUserContext> fetchCurrentUserContext(ApiClient api) async {
  final response = await api.dio.get('/auth/me');
  final payload = response.data as Map<String, dynamic>? ?? {};
  final tenant = payload['tenant'] as Map<String, dynamic>? ?? {};
  return CurrentUserContext(
    role: payload['role']?.toString(),
    userName: payload['name']?.toString(),
    shopName: tenant['shopName']?.toString(),
  );
}

String profileInitialsFromName(String? value, {String fallback = 'SL'}) {
  final words =
      value
          ?.trim()
          .split(RegExp(r'[^A-Za-z0-9]+'))
          .where((word) => word.isNotEmpty)
          .toList() ??
      const <String>[];

  if (words.isEmpty) return fallback;

  if (words.length == 1) {
    final word = words.first;
    return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
  }

  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}
