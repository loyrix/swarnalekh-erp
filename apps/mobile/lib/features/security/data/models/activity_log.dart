// Typed activity-log models for the Security screen (no Map in presentation).

String? _s(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

/// One audit entry from `GET /security/activity-logs`.
class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.userName,
    required this.userRole,
    required this.ipAddress,
    required this.createdAt,
  });

  final String id;
  final String action;
  final String entityType;
  final String? entityId;
  final String? userName;
  final String? userRole;
  final String? ipAddress;
  final DateTime? createdAt;

  bool get isBackup => action == 'backup_export';

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map ? user.cast<String, dynamic>() : const {};
    return ActivityLog(
      id: (json['id'] ?? '').toString(),
      action: _s(json['action']) ?? 'activity',
      entityType: _s(json['entityType']) ?? 'system',
      entityId: _s(json['entityId']),
      userName: _s(userMap['name']),
      userRole: _s(userMap['role']),
      ipAddress: _s(json['ipAddress']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

/// A page of activity logs plus the total match count.
class ActivityLogPage {
  const ActivityLogPage({
    required this.logs,
    required this.total,
    required this.generatedAt,
  });

  final List<ActivityLog> logs;
  final int total;
  final DateTime? generatedAt;

  /// The most recent backup export, if any log in the page is one.
  ActivityLog? get latestBackup {
    for (final log in logs) {
      if (log.isBackup) return log;
    }
    return null;
  }

  factory ActivityLogPage.fromJson(Map<String, dynamic> json) {
    final raw = json['logs'];
    return ActivityLogPage(
      logs: raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(ActivityLog.fromJson)
                .toList()
          : const [],
      total: _i(json['total']),
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? ''),
    );
  }
}
