import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/features/reports/data/models/reports_data.dart';
import 'package:swarnbook/features/reports/data/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(),
);

final reportsProvider = FutureProvider.autoDispose
    .family<ReportsData, ReportsQuery>((ref, query) {
      return ref.watch(reportsRepositoryProvider).getOverview(query);
    });
