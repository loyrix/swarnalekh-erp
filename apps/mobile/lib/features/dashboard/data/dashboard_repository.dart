import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/dashboard/data/models/dashboard_data.dart';

class DashboardRepository {
  static final DashboardRepository _instance = DashboardRepository._internal();
  factory DashboardRepository() => _instance;
  DashboardRepository._internal();

  final ApiClient _api = ApiClient();

  Future<DashboardData> getBootstrap() async {
    final response = await _api.dio.get('/dashboard/bootstrap');
    final payload = response.data as Map<String, dynamic>? ?? const {};
    return DashboardData.fromBootstrap(payload);
  }
}
