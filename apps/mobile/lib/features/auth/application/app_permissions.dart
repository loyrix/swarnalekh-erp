import 'package:swarnbook/core/network/api_client.dart';

bool isAdminRole(String? role) {
  final value = role?.trim().toLowerCase();
  return value == 'owner' || value == 'admin';
}

bool isStaffRole(String? role) => role?.trim().toLowerCase() == 'staff';

Future<String?> fetchCurrentUserRole(ApiClient api) async {
  final response = await api.dio.get('/auth/me');
  final payload = response.data as Map<String, dynamic>? ?? {};
  return payload['role']?.toString();
}
