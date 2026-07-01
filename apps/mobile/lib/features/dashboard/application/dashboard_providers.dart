import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/features/dashboard/data/dashboard_repository.dart';
import 'package:swarnbook/features/dashboard/data/models/dashboard_data.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(),
);

/// Loads the dashboard bootstrap payload. Refresh via `ref.invalidate`.
final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) {
  return ref.watch(dashboardRepositoryProvider).getBootstrap();
});
