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
