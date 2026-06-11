import 'package:swarnbook/core/network/api_client.dart';
import '../models/tenant_profile.dart';

class TenantRepository {
  final ApiClient _api = ApiClient();

  Future<TenantProfile> getProfile() async {
    final response = await _api.dio.get('/tenant/profile');
    return TenantProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TenantProfile> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.dio.put('/tenant/profile', data: data);
    return TenantProfile.fromJson(response.data as Map<String, dynamic>);
  }
}
