import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/features/security/data/models/activity_log.dart';
import 'package:swarnbook/features/security/data/security_repository.dart';

final securityRepositoryProvider = Provider<SecurityRepository>(
  (ref) => SecurityRepository(),
);

final activityLogsProvider = FutureProvider.autoDispose
    .family<ActivityLogPage, SecurityQuery>((ref, query) {
      return ref.watch(securityRepositoryProvider).getActivityLogs(query);
    });
