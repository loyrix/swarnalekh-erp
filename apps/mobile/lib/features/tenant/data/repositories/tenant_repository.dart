import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/tenant/application/tenant_profile_payload.dart';
import '../models/tenant_profile.dart';

class TenantRepository {
  final ApiClient _api = ApiClient();

  Future<TenantProfile> getProfile() async {
    final response = await _api.dio.get('/tenant/profile');
    return TenantProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TenantProfile> updateProfile(TenantProfileUpdateInput input) async {
    final response = await _api.dio.put(
      '/tenant/profile',
      data: input.toJson(),
    );
    return TenantProfile.fromJson(response.data as Map<String, dynamic>);
  }
}
