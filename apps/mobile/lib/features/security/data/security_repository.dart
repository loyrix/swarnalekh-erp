import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/security/application/security_payloads.dart';
import 'package:swarnbook/features/security/data/models/activity_log.dart';

/// Immutable filter for the activity-log list. Value equality keys the
/// Riverpod provider family so identical queries share one request.
class SecurityQuery {
  const SecurityQuery({
    this.search = '',
    this.entityType = 'all',
    this.action = 'all',
  });

  final String search;
  final String entityType;
  final String action;

  SecurityQuery copyWith({String? search, String? entityType, String? action}) {
    return SecurityQuery(
      search: search ?? this.search,
      entityType: entityType ?? this.entityType,
      action: action ?? this.action,
    );
  }

  bool get hasActiveFilters => entityType != 'all' || action != 'all';

  Map<String, dynamic> toQueryParameters() {
    return {
      'limit': 50,
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (entityType != 'all') 'entityType': entityType,
      if (action != 'all') 'action': action,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is SecurityQuery &&
      other.search == search &&
      other.entityType == entityType &&
      other.action == action;

  @override
  int get hashCode => Object.hash(search, entityType, action);
}

class SecurityRepository {
  static final SecurityRepository _instance = SecurityRepository._internal();
  factory SecurityRepository() => _instance;
  SecurityRepository._internal();

  final ApiClient _api = ApiClient();

  Future<ActivityLogPage> getActivityLogs(SecurityQuery query) async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/security/activity-logs',
      queryParameters: query.toQueryParameters(),
    );
    return ActivityLogPage.fromJson(response.data ?? const {});
  }

  Future<BackupPayload> createBackup() async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/security/backup',
    );
    return decodeBackupPayload(response.data ?? const {});
  }
}
